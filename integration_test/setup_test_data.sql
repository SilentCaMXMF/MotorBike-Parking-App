-- Integration Test Data Setup
-- Run this script to create test data for integration tests
-- 
-- Usage:
--   mysql -h 192.168.1.67 -u motorbike_app -p motorbike_parking_app < integration_test/setup_test_data.sql

-- ============================================================================
-- TEST USER
-- ============================================================================

-- Create test user
-- Password: TestPassword123
-- Hash generated with: node integration_test/generate_test_password.js
INSERT INTO users (id, email, password_hash, is_anonymous, created_at, updated_at)
VALUES (
  'test_user_integration',
  'test@example.com',
  '$2b$10$06lton2WyffHAam1qhO/UOlLoTZ0cKOcLtRD7PirlENF4uP9vZOkW',
  0,
  NOW(),
  NOW()
) ON DUPLICATE KEY UPDATE 
  email = VALUES(email),
  updated_at = NOW();

SELECT 'Test user created/updated' AS status;

-- ============================================================================
-- TEST PARKING ZONES
-- ============================================================================

-- Create test parking zone 1
INSERT INTO parking_zones (
  id,
  google_places_id,
  latitude,
  longitude,
  total_capacity,
  current_occupancy,
  confidence_score,
  last_updated
) VALUES (
  'test_zone_123',
  'ChIJTestZone123',
  38.7223,
  -9.1393,
  10,
  5,
  0.8,
  NOW()
) ON DUPLICATE KEY UPDATE 
  last_updated = NOW(),
  current_occupancy = 5,
  confidence_score = 0.8;

-- Create test parking zone 2
INSERT INTO parking_zones (
  id,
  google_places_id,
  latitude,
  longitude,
  total_capacity,
  current_occupancy,
  confidence_score,
  last_updated
) VALUES (
  'test_zone_456',
  'ChIJTestZone456',
  38.7250,
  -9.1400,
  15,
  8,
  0.9,
  NOW()
) ON DUPLICATE KEY UPDATE 
  last_updated = NOW(),
  current_occupancy = 8,
  confidence_score = 0.9;

SELECT 'Test parking zones created/updated' AS status;

-- ============================================================================
-- VERIFY TEST DATA
-- ============================================================================

SELECT 'Test User:' AS info;
SELECT id, email, is_anonymous, created_at 
FROM users 
WHERE id = 'test_user_integration';

SELECT 'Test Parking Zones:' AS info;
SELECT id, latitude, longitude, total_capacity, current_occupancy 
FROM parking_zones 
WHERE id LIKE 'test_zone_%';

-- ============================================================================
-- CLEANUP SCRIPT (commented out - uncomment to clean up)
-- ============================================================================

/*
-- Remove test reports
DELETE FROM user_reports 
WHERE user_id = 'test_user_integration';

-- Remove test user
DELETE FROM users 
WHERE id = 'test_user_integration';

-- Remove test zones
DELETE FROM parking_zones 
WHERE id LIKE 'test_zone_%';

SELECT 'Test data cleaned up' AS status;
*/

