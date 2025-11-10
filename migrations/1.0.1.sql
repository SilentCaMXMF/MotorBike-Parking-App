-- Migration: 1.0.1
-- Description: Add user profile fields and indexes for better performance
-- Applied: 2025-11-10

START TRANSACTION;

-- Add user profile fields
ALTER TABLE users 
ADD COLUMN first_name VARCHAR(100) NULL AFTER email,
ADD COLUMN last_name VARCHAR(100) NULL AFTER first_name,
ADD COLUMN phone_number VARCHAR(20) NULL AFTER last_name,
ADD COLUMN avatar_url VARCHAR(500) NULL AFTER phone_number,
ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT FALSE AFTER avatar_url,
ADD COLUMN last_login TIMESTAMP NULL AFTER email_verified;

-- Add indexes for better query performance
CREATE INDEX idx_users_last_login ON users(last_login);
CREATE INDEX idx_users_email_verified ON users(email_verified);

-- Add parking zone metadata
ALTER TABLE parking_zones
ADD COLUMN zone_name VARCHAR(255) NULL AFTER google_places_id,
ADD COLUMN address TEXT NULL AFTER zone_name,
ADD COLUMN city VARCHAR(100) NULL AFTER address,
ADD COLUMN postal_code VARCHAR(20) NULL AFTER city,
ADD COLUMN country VARCHAR(100) NULL AFTER postal_code,
ADD COLUMN parking_type ENUM('street', 'garage', 'lot', 'private') NOT NULL DEFAULT 'street' AFTER country,
ADD COLUMN hourly_rate DECIMAL(8, 2) NULL AFTER parking_type,
ADD COLUMN max_stay_hours INT NULL AFTER hourly_rate,
ADD COLUMN operating_hours JSON NULL AFTER max_stay_hours;

-- Add indexes for new parking zone fields
CREATE INDEX idx_parking_zones_city ON parking_zones(city);
CREATE INDEX idx_parking_zones_parking_type ON parking_zones(parking_type);
CREATE INDEX idx_parking_zones_hourly_rate ON parking_zones(hourly_rate);

-- Add report verification workflow
ALTER TABLE user_reports
ADD COLUMN verification_method ENUM('none', 'photo', 'multiple_users', 'admin') NOT NULL DEFAULT 'none' AFTER is_verified,
ADD COLUMN verification_notes TEXT NULL AFTER verification_method,
ADD COLUMN moderator_id CHAR(36) NULL AFTER verification_notes,
ADD COLUMN verified_at TIMESTAMP NULL AFTER moderator_id;

-- Add foreign key for moderator
ALTER TABLE user_reports
ADD CONSTRAINT fk_user_reports_moderator 
FOREIGN KEY (moderator_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- Add indexes for verification fields
CREATE INDEX idx_user_reports_verification_method ON user_reports(verification_method);
CREATE INDEX idx_user_reports_moderator_id ON user_reports(moderator_id);
CREATE INDEX idx_user_reports_verified_at ON user_reports(verified_at);

-- Add image processing metadata
ALTER TABLE report_images
ADD COLUMN processing_status ENUM('pending', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'pending' AFTER is_processed,
ADD COLUMN processing_error TEXT NULL AFTER processing_status,
ADD COLUMN ai_confidence DECIMAL(3, 2) NULL AFTER processing_error,
ADD COLUMN detected_objects JSON NULL AFTER ai_confidence,
ADD COLUMN thumbnail_url VARCHAR(500) NULL AFTER detected_objects,
ADD COLUMN processed_at TIMESTAMP NULL AFTER thumbnail_url;

-- Add indexes for image processing
CREATE INDEX idx_report_images_processing_status ON report_images(processing_status);
CREATE INDEX idx_report_images_ai_confidence ON report_images(ai_confidence);
CREATE INDEX idx_report_images_processed_at ON report_images(processed_at);

-- Update views to include new fields
DROP VIEW IF EXISTS parking_zone_availability;
CREATE VIEW parking_zone_availability AS
SELECT 
    pz.id,
    pz.google_places_id,
    pz.zone_name,
    pz.address,
    pz.city,
    pz.postal_code,
    pz.country,
    pz.parking_type,
    pz.hourly_rate,
    pz.max_stay_hours,
    pz.operating_hours,
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
    COUNT(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN 1 END) AS reports_1h,
    COUNT(CASE WHEN ur.is_verified = TRUE THEN 1 END) AS verified_reports
FROM parking_zones pz
LEFT JOIN user_reports ur ON pz.id = ur.spot_id
WHERE pz.is_active = TRUE
GROUP BY pz.id;

-- Update recent reports view
DROP VIEW IF EXISTS recent_user_reports;
CREATE VIEW recent_user_reports AS
SELECT 
    ur.id,
    ur.spot_id,
    ur.user_id,
    u.email AS user_email,
    u.first_name AS user_first_name,
    u.last_name AS user_last_name,
    u.is_anonymous AS user_is_anonymous,
    ur.reported_count,
    ur.timestamp,
    ur.user_latitude,
    ur.user_longitude,
    ur.is_verified,
    ur.verification_method,
    ur.verification_notes,
    ur.moderator_id,
    ur.verified_at,
    pz.zone_name AS spot_name,
    pz.parking_type AS spot_type,
    pz.latitude AS spot_latitude,
    pz.longitude AS spot_longitude,
    COUNT(ri.id) AS image_count,
    COUNT(CASE WHEN ri.processing_status = 'completed' THEN 1 END) AS processed_images
FROM user_reports ur
JOIN users u ON ur.user_id = u.id
JOIN parking_zones pz ON ur.spot_id = pz.id
LEFT JOIN report_images ri ON ur.id = ri.report_id
WHERE ur.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY ur.id
ORDER BY ur.timestamp DESC;

-- Create new stored procedure for user statistics
DELIMITER //
CREATE PROCEDURE GetUserStatistics(
    IN p_user_id CHAR(36)
)
BEGIN
    SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.created_at,
        u.last_login,
        COUNT(ur.id) AS total_reports,
        COUNT(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) AS reports_30_days,
        COUNT(CASE WHEN ur.is_verified = TRUE THEN 1 END) AS verified_reports,
        COUNT(DISTINCT ur.spot_id) AS unique_spots_reported,
        COUNT(ri.id) AS total_images_uploaded,
        AVG(ur.reported_count) AS avg_reported_count
    FROM users u
    LEFT JOIN user_reports ur ON u.id = ur.user_id
    LEFT JOIN report_images ri ON ur.id = ri.report_id
    WHERE u.id = p_user_id
    GROUP BY u.id;
END//
DELIMITER ;

-- Create new stored procedure for parking zone analytics
DELIMITER //
CREATE PROCEDURE GetParkingZoneAnalytics(
    IN p_spot_id CHAR(36),
    IN p_days_back INT DEFAULT 30
)
BEGIN
    SELECT 
        pz.id,
        pz.zone_name,
        pz.parking_type,
        pz.total_capacity,
        pz.current_occupancy,
        pz.confidence_score,
        COUNT(ur.id) AS total_reports,
        COUNT(CASE WHEN ur.timestamp >= DATE_SUB(NOW(), INTERVAL p_days_back DAY) THEN 1 END) AS reports_period,
        COUNT(CASE WHEN ur.is_verified = TRUE THEN 1 END) AS verified_reports,
        AVG(ur.reported_count) AS avg_reported_count,
        MAX(ur.timestamp) AS last_report,
        COUNT(DISTINCT ur.user_id) AS unique_reporters,
        COUNT(ri.id) AS total_images,
        COUNT(CASE WHEN ri.processing_status = 'completed' THEN 1 END) AS processed_images
    FROM parking_zones pz
    LEFT JOIN user_reports ur ON pz.id = ur.spot_id
    LEFT JOIN report_images ri ON ur.id = ri.report_id
    WHERE pz.id = p_spot_id
    GROUP BY pz.id;
END//
DELIMITER ;

COMMIT;