# Integration Tests

This directory contains integration tests that connect to the actual backend API and database.

## Prerequisites

### 1. Backend Server Running

Start the Node+Express backend server:

```bash
cd backend
npm run dev
```

The server should be running at `http://localhost:3000` (or your configured URL).

### 2. Database Setup

Ensure the MariaDB database is running and contains test data:

#### Create Test User

```sql
-- Connect to database
mysql -h 192.168.1.67 -u motorbike_app -p motorbike_parking_app

-- Create test user (if not exists)
INSERT INTO users (id, email, password_hash, is_anonymous, created_at)
VALUES (
  'test_user_integration',
  'test@example.com',
  '$2b$10$YourBcryptHashHere',  -- Hash of 'TestPassword123'
  0,
  NOW()
) ON DUPLICATE KEY UPDATE email=email;
```

To generate the password hash:

```bash
cd backend
node -e "const bcrypt = require('bcrypt'); bcrypt.hash('TestPassword123', 10, (err, hash) => console.log(hash));"
```

#### Create Test Parking Zone

```sql
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
) ON DUPLICATE KEY UPDATE last_updated=NOW();
```

### 3. Environment Configuration

The tests use these default values (can be overridden with environment variables):

- `TEST_API_URL`: `http://localhost:3000`
- `TEST_DB_HOST`: `192.168.1.67`
- `TEST_DB_NAME`: `motorbike_parking_app`
- `TEST_DB_USER`: `motorbike_app`
- `TEST_DB_PASSWORD`: (from environment)

## Running Tests

### Run All Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Test File

```bash
flutter test integration_test/reporting_dialog_integration_test.dart
```

### Run with Custom API URL

```bash
flutter test integration_test/ --dart-define=TEST_API_URL=http://192.168.1.67:3000
```

### Run with Verbose Output

```bash
flutter test integration_test/ --verbose
```

### Run on Physical Device

```bash
# Android
flutter test integration_test/ --device-id=<device-id>

# iOS
flutter test integration_test/ --device-id=<device-id>
```

## Test Structure

### `config.dart`

Configuration values for integration tests:
- API URLs
- Test credentials
- Database connection settings
- Timeouts

### `reporting_dialog_integration_test.dart`

Integration tests for ReportingDialog widget:
- Submit report successfully to backend
- Handle API validation errors
- Display error message on network failure
- Verify SqlService integration

## Test Scenarios

### 1. Submit Report Successfully

**What it tests:**
- Opening ReportingDialog
- Submitting a report to the backend
- Loading indicator display
- Success message display

**Expected result:**
- Report is saved to database
- Success SnackBar appears
- Dialog closes

### 2. Handle API Validation Errors

**What it tests:**
- Submitting invalid data
- API validation error handling
- Error message display

**Expected result:**
- Validation error from API
- Error message displayed to user
- Report not saved to database

### 3. Display Error on Network Failure

**What it tests:**
- Network error handling
- Error message display
- Retry capability

**Expected result:**
- Error message displayed
- Retry button available
- User can retry submission

### 4. Verify SqlService Integration

**What it tests:**
- SqlService.getParkingZones()
- SqlService.addUserReport()
- API communication
- Data parsing

**Expected result:**
- API calls succeed
- Data is correctly parsed
- Reports are saved to database

## Troubleshooting

### "Authentication failed"

**Problem:** Test user doesn't exist in database or password is incorrect.

**Solution:**
1. Check test user exists: `SELECT * FROM users WHERE email='test@example.com';`
2. Verify password hash is correct
3. Update test credentials in `config.dart` if needed

### "Connection refused"

**Problem:** Backend server is not running.

**Solution:**
1. Start backend: `cd backend && npm run dev`
2. Verify server is accessible: `curl http://localhost:3000/health`
3. Check firewall settings if using Raspberry Pi

### "Test zone not found"

**Problem:** Test parking zone doesn't exist in database.

**Solution:**
1. Create test zone using SQL above
2. Verify zone exists: `SELECT * FROM parking_zones WHERE id='test_zone_123';`

### "Database connection failed"

**Problem:** Cannot connect to MariaDB database.

**Solution:**
1. Verify database is running: `systemctl status mariadb`
2. Check connection settings in `config.dart`
3. Verify network connectivity to Raspberry Pi
4. Check database user permissions

## Cleanup

### Remove Test Data

After running tests, clean up test data:

```sql
-- Remove test reports
DELETE FROM user_reports 
WHERE user_id = 'test_user_integration' 
AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);

-- Remove test images
DELETE FROM report_images 
WHERE report_id IN (
  SELECT id FROM user_reports WHERE user_id = 'test_user_integration'
);
```

### Automated Cleanup

The tests automatically clean up auth tokens after completion. Database cleanup should be done manually or via a cleanup script.

## CI/CD Integration

To run integration tests in CI/CD:

1. Set up test database
2. Start backend server in test mode
3. Run tests with environment variables:

```bash
flutter test integration_test/ \
  --dart-define=TEST_API_URL=$TEST_API_URL \
  --dart-define=TEST_DB_PASSWORD=$TEST_DB_PASSWORD
```

## Best Practices

1. **Always run backend server first** before running tests
2. **Use test database** separate from production
3. **Clean up test data** after test runs
4. **Don't commit credentials** - use environment variables
5. **Run tests locally** before pushing to CI/CD

## Next Steps

- [ ] Add image upload integration test
- [ ] Add database verification helpers
- [ ] Add test for authentication token expiration
- [ ] Add test for rate limiting
- [ ] Add performance benchmarks
- [ ] Integrate with CI/CD pipeline

## References

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Backend API Documentation](../backend/README.md)
- [Task 15.2 Plan](../test/TASK_15_2_INTEGRATION_TEST_PLAN.md)

