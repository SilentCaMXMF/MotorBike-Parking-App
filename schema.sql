-- Motorbike Parking App Database Schema
-- Compatible with MariaDB/MySQL 8.0+
-- Created: 2025-11-10

-- Enable UUID functions
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS motorbike_parking_app 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE motorbike_parking_app;

-- ========================================
-- TABLES
-- ========================================

-- Users table for authentication and user management
CREATE TABLE users (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL, -- NULL for anonymous users
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    INDEX idx_users_email (email),
    INDEX idx_users_created_at (created_at),
    INDEX idx_users_is_active (is_active)
) ENGINE=InnoDB;

-- Parking zones table for parking spot information
CREATE TABLE parking_zones (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    google_places_id VARCHAR(255) NULL UNIQUE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    total_capacity INT NOT NULL DEFAULT 0,
    current_occupancy INT NOT NULL DEFAULT 0,
    confidence_score DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    INDEX idx_parking_zones_google_places (google_places_id),
    INDEX idx_parking_zones_location (latitude, longitude),
    INDEX idx_parking_zones_last_updated (last_updated),
    INDEX idx_parking_zones_is_active (is_active),
    
    -- Ensure coordinates are valid
    CONSTRAINT chk_latitude CHECK (latitude >= -90 AND latitude <= 90),
    CONSTRAINT chk_longitude CHECK (longitude >= -180 AND longitude <= 180),
    CONSTRAINT chk_capacity CHECK (total_capacity >= 0),
    CONSTRAINT chk_occupancy CHECK (current_occupancy >= 0 AND current_occupancy <= total_capacity),
    CONSTRAINT chk_confidence CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00)
) ENGINE=InnoDB;

-- User reports table for parking availability reports
CREATE TABLE user_reports (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    spot_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    reported_count INT NOT NULL DEFAULT 1,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_latitude DECIMAL(10, 8) NULL,
    user_longitude DECIMAL(11, 8) NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    INDEX idx_user_reports_spot_id (spot_id),
    INDEX idx_user_reports_user_id (user_id),
    INDEX idx_user_reports_timestamp (timestamp),
    INDEX idx_user_reports_is_verified (is_verified),
    
    FOREIGN KEY (spot_id) REFERENCES parking_zones(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Ensure reported count is positive
    CONSTRAINT chk_reported_count CHECK (reported_count > 0),
    -- Ensure user coordinates are valid if provided
    CONSTRAINT chk_user_latitude CHECK (user_latitude IS NULL OR (user_latitude >= -90 AND user_latitude <= 90)),
    CONSTRAINT chk_user_longitude CHECK (user_longitude IS NULL OR (user_longitude >= -180 AND user_longitude <= 180))
) ENGINE=InnoDB;

-- Report images table for storing image metadata
CREATE TABLE report_images (
    id CHAR(36) NOT NULL DEFAULT (UUID()),
    report_id CHAR(36) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    mime_type VARCHAR(100) NOT NULL DEFAULT 'image/jpeg',
    width INT NULL,
    height INT NULL,
    is_processed BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    INDEX idx_report_images_report_id (report_id),
    INDEX idx_report_images_uploaded_at (uploaded_at),
    INDEX idx_report_images_is_processed (is_processed),
    
    FOREIGN KEY (report_id) REFERENCES user_reports(id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Ensure file size is positive
    CONSTRAINT chk_file_size CHECK (file_size >= 0),
    -- Ensure dimensions are positive if provided
    CONSTRAINT chk_width CHECK (width IS NULL OR width > 0),
    CONSTRAINT chk_height CHECK (height IS NULL OR height > 0)
) ENGINE=InnoDB;

-- ========================================
-- VIEWS FOR COMMON QUERIES
-- ========================================

-- View for parking zones with availability information
CREATE VIEW parking_zone_availability AS
SELECT 
    pz.id,
    pz.google_places_id,
    pz.latitude,
    pz.longitude,
    pz.total_capacity,
    pz.current_occupancy,
    (pz.total_capacity - pz.current_occupancy) AS available_slots,
    pz.confidence_score,
    pz.last_updated,
    pz.is_active,
    COUNT(ur.id) AS total_reports,
    COUNT(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 END) AS reports_24h,
    COUNT(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN 1 END) AS reports_1h
FROM parking_zones pz
LEFT JOIN user_reports ur ON pz.id = ur.spot_id
WHERE pz.is_active = TRUE
GROUP BY pz.id;

-- View for recent user reports with user information
CREATE VIEW recent_user_reports AS
SELECT 
    ur.id,
    ur.spot_id,
    ur.user_id,
    u.email AS user_email,
    u.is_anonymous AS user_is_anonymous,
    ur.reported_count,
    ur.timestamp,
    ur.user_latitude,
    ur.user_longitude,
    ur.is_verified,
    pz.latitude AS spot_latitude,
    pz.longitude AS spot_longitude,
    COUNT(ri.id) AS image_count
FROM user_reports ur
JOIN users u ON ur.user_id = u.id
JOIN parking_zones pz ON ur.spot_id = pz.id
LEFT JOIN report_images ri ON ur.id = ri.report_id
WHERE ur.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY ur.id
ORDER BY ur.timestamp DESC;

-- ========================================
-- TRIGGERS FOR DATA INTEGRITY
-- ========================================

-- Trigger to update parking zone occupancy when reports are added
DELIMITER //
CREATE TRIGGER update_occupancy_on_report_insert
AFTER INSERT ON user_reports
FOR EACH ROW
BEGIN
    UPDATE parking_zones 
    SET current_occupancy = (
        SELECT COALESCE(SUM(reported_count), 0) 
        FROM user_reports 
        WHERE spot_id = NEW.spot_id 
        AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    ),
    confidence_score = LEAST(
        CASE 
            WHEN (SELECT COUNT(*) FROM user_reports WHERE spot_id = NEW.spot_id AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)) >= 3 THEN 0.95
            WHEN (SELECT COUNT(*) FROM user_reports WHERE spot_id = NEW.spot_id AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)) >= 2 THEN 0.80
            ELSE 0.60
        END, 1.00
    ),
    last_updated = CURRENT_TIMESTAMP
    WHERE id = NEW.spot_id;
END//
DELIMITER ;

-- Trigger to update parking zone occupancy when reports are deleted
DELIMITER //
CREATE TRIGGER update_occupancy_on_report_delete
AFTER DELETE ON user_reports
FOR EACH ROW
BEGIN
    UPDATE parking_zones 
    SET current_occupancy = (
        SELECT COALESCE(SUM(reported_count), 0) 
        FROM user_reports 
        WHERE spot_id = OLD.spot_id 
        AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    ),
    confidence_score = LEAST(
        CASE 
            WHEN (SELECT COUNT(*) FROM user_reports WHERE spot_id = OLD.spot_id AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)) >= 3 THEN 0.95
            WHEN (SELECT COUNT(*) FROM user_reports WHERE spot_id = OLD.spot_id AND timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)) >= 2 THEN 0.80
            ELSE 0.60
        END, 1.00
    ),
    last_updated = CURRENT_TIMESTAMP
    WHERE id = OLD.spot_id;
END//
DELIMITER ;

-- ========================================
-- STORED PROCEDURES FOR COMMON OPERATIONS
-- ========================================

-- Procedure to get nearby parking zones
DELIMITER //
CREATE PROCEDURE GetNearbyParkingZones(
    IN p_latitude DECIMAL(10, 8),
    IN p_longitude DECIMAL(11, 8),
    IN p_radius_km DECIMAL(8, 3),
    IN p_limit INT
)
BEGIN
    SELECT 
        pza.*,
        (
            6371 * ACOS(
                COS(RADIANS(p_latitude)) * 
                COS(RADIANS(pza.latitude)) * 
                COS(RADIANS(pza.longitude) - RADIANS(p_longitude)) + 
                SIN(RADIANS(p_latitude)) * 
                SIN(RADIANS(pza.latitude))
            )
        ) AS distance_km
    FROM parking_zone_availability pza
    HAVING distance_km <= p_radius_km
    ORDER BY distance_km ASC, pza.confidence_score DESC
    LIMIT p_limit;
END//
DELIMITER ;

-- Procedure to create a new user report
DELIMITER //
CREATE PROCEDURE CreateUserReport(
    IN p_spot_id CHAR(36),
    IN p_user_id CHAR(36),
    IN p_reported_count INT,
    IN p_user_latitude DECIMAL(10, 8),
    IN p_user_longitude DECIMAL(11, 8)
)
BEGIN
    DECLARE v_report_id CHAR(36);
    
    -- Generate UUID for the report
    SET v_report_id = UUID();
    
    -- Insert the report
    INSERT INTO user_reports (
        id, spot_id, user_id, reported_count, user_latitude, user_longitude
    ) VALUES (
        v_report_id, p_spot_id, p_user_id, p_reported_count, p_user_latitude, p_user_longitude
    );
    
    -- Return the report ID
    SELECT v_report_id AS report_id;
END//
DELIMITER ;

-- ========================================
-- INITIAL DATA
-- ========================================

-- Insert default anonymous user if not exists
INSERT IGNORE INTO users (id, email, is_anonymous, is_active) 
VALUES (UUID(), 'anonymous@motorbike-parking.app', TRUE, TRUE);

-- ========================================
-- PERFORMANCE OPTIMIZATION
-- ========================================

-- Set up partitioning for user_reports by date (optional for large datasets)
-- ALTER TABLE user_reports PARTITION BY RANGE (UNIX_TIMESTAMP(timestamp)) (
--     PARTITION p_current VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01')),
--     PARTITION p_future VALUES LESS THAN MAXVALUE
-- );

-- Set up appropriate storage engine settings
SET GLOBAL innodb_file_per_table = ON;
SET GLOBAL innodb_file_format = Barracuda;
SET GLOBAL innodb_large_prefix = ON;

SET FOREIGN_KEY_CHECKS = 1;

-- ========================================
-- GRANTS AND SECURITY
-- ========================================

-- Create application user (adjust password as needed)
-- CREATE USER 'motorbike_app'@'%' IDENTIFIED BY 'secure_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON motorbike_parking_app.* TO 'motorbike_app'@'%';
-- FLUSH PRIVILEGES;

-- ========================================
-- SCHEMA VERSION TRACKING
-- ========================================

CREATE TABLE schema_version (
    version VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (version)
) ENGINE=InnoDB;

INSERT INTO schema_version (version, description) VALUES (
    '1.0.0', 
    'Initial schema creation with users, parking_zones, user_reports, and report_images tables'
);