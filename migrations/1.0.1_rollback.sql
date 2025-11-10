-- Rollback: 1.0.1
-- Description: Rollback for: Add user profile fields and indexes for better performance
-- Applied: 2025-11-10

START TRANSACTION;

-- Drop stored procedures
DROP PROCEDURE IF EXISTS GetUserStatistics;
DROP PROCEDURE IF EXISTS GetParkingZoneAnalytics;

-- Drop updated views
DROP VIEW IF EXISTS recent_user_reports;
DROP VIEW IF EXISTS parking_zone_availability;

-- Recreate original views
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

-- Drop indexes for image processing
DROP INDEX IF EXISTS idx_report_images_processing_status ON report_images;
DROP INDEX IF EXISTS idx_report_images_ai_confidence ON report_images;
DROP INDEX IF EXISTS idx_report_images_processed_at ON report_images;

-- Remove image processing metadata columns
ALTER TABLE report_images
DROP COLUMN IF EXISTS processing_status,
DROP COLUMN IF EXISTS processing_error,
DROP COLUMN IF EXISTS ai_confidence,
DROP COLUMN IF EXISTS detected_objects,
DROP COLUMN IF EXISTS thumbnail_url,
DROP COLUMN IF EXISTS processed_at;

-- Drop indexes for verification fields
DROP INDEX IF EXISTS idx_user_reports_verification_method ON user_reports;
DROP INDEX IF EXISTS idx_user_reports_moderator_id ON user_reports;
DROP INDEX IF EXISTS idx_user_reports_verified_at ON user_reports;

-- Remove foreign key for moderator
ALTER TABLE user_reports DROP FOREIGN KEY IF EXISTS fk_user_reports_moderator;

-- Remove report verification workflow columns
ALTER TABLE user_reports
DROP COLUMN IF EXISTS verification_method,
DROP COLUMN IF EXISTS verification_notes,
DROP COLUMN IF EXISTS moderator_id,
DROP COLUMN IF EXISTS verified_at;

-- Drop indexes for new parking zone fields
DROP INDEX IF EXISTS idx_parking_zones_city ON parking_zones;
DROP INDEX IF EXISTS idx_parking_zones_parking_type ON parking_zones;
DROP INDEX IF EXISTS idx_parking_zones_hourly_rate ON parking_zones;

-- Remove parking zone metadata
ALTER TABLE parking_zones
DROP COLUMN IF EXISTS zone_name,
DROP COLUMN IF EXISTS address,
DROP COLUMN IF EXISTS city,
DROP COLUMN IF EXISTS postal_code,
DROP COLUMN IF EXISTS country,
DROP COLUMN IF EXISTS parking_type,
DROP COLUMN IF EXISTS hourly_rate,
DROP COLUMN IF EXISTS max_stay_hours,
DROP COLUMN IF EXISTS operating_hours;

-- Drop indexes for user profile fields
DROP INDEX IF EXISTS idx_users_last_login ON users;
DROP INDEX IF EXISTS idx_users_email_verified ON users;

-- Remove user profile fields
ALTER TABLE users
DROP COLUMN IF EXISTS first_name,
DROP COLUMN IF EXISTS last_name,
DROP COLUMN IF EXISTS phone_number,
DROP COLUMN IF EXISTS avatar_url,
DROP COLUMN IF EXISTS email_verified,
DROP COLUMN IF EXISTS last_login;

COMMIT;