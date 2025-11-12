# Task 15.2: Integration Testing Plan for ReportingDialog

## Overview

This document outlines the replanned approach for Task 15.2, which now focuses on **integration testing** with the actual Node+Express backend and MariaDB database, rather than unit testing with mocks.

## Background

The original task 15.2 attempted to create widget tests using mocked services (MockSqlService, MockLocationService). However, this approach encountered several technical challenges:

1. **Type system conflicts**: Dart's strict type system prevented MockSqlService from being cast to SqlService
2. **Mockito compatibility**: Custom mock classes conflicted with mockito's `when()` function
3. **Limited value**: Mocking the entire backend doesn't test the actual integration between Flutter app and API

## New Approach: Integration Testing

Instead of mocking, we'll test the **actual integration** between:

- Flutter app (ReportingDialog widget)
- Node+Express REST API (running on localhost or Raspberry Pi)
- MariaDB database (data persistence verification)

## Test Environment Setup

### Prerequisites

1. **Backend Server Running**

   - Node+Express API at `http://localhost:3000` or Raspberry Pi IP
   - MariaDB database accessible and seeded with test data
   - Test user account created for authentication

2. **Flutter Test Configuration**
   - Integration test directory: `integration_test/`
   - Test database: Separate test database or test data cleanup strategy
   - Environment variables for test API endpoint

### Backend Test Server

The backend is already set up with:

- **Express server**: `backend/src/server.js`
- **Database**: MariaDB on Raspberry Pi (192.168.1.67:3306)
- **API endpoints**:
  - `POST /api/auth/login` - Authentication
  - `POST /api/reports` - Submit report
  - `POST /api/reports/:id/images` - Upload image
  - `GET /api/parking/nearby` - Get parking zones

## Integration Test Structure

### Test File: `integration_test/reporting_dialog_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motorbike_parking_app/main.dart' as app;
import 'package:motorbike_parking_app/services/api_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ReportingDialog Integration Tests', () {
    setUpAll(() async {
      // Initialize API service with test backend URL
      // Authenticate test user
      // Seed test data in database
    });

    tearDownAll(() async {
      // Clean up test data
      // Logout test user
    });

    testWidgets('Submit report successfully to backend', (tester) async {
      // Test actual report submission flow
    });

    testWidgets('Upload image successfully to backend', (tester) async {
      // Test actual image upload flow
    });

    testWidgets('Handle network errors gracefully', (tester) async {
      // Test with backend temporarily unavailable
    });

    testWidgets('Verify data persists in database', (tester) async {
      // Query database to verify report was saved
    });
  });
}
```

## Test Scenarios

### 1. Successful Report Submission

**Test Steps:**

1. Launch app and navigate to map
2. Tap on a parking zone marker
3. Open ReportingDialog
4. Adjust occupancy count slider
5. Tap "Submit" button
6. Verify loading indicator appears
7. Wait for API call to complete
8. Verify success message appears
9. Query database to confirm report was saved

**Expected Results:**

- Loading indicator shows during submission
- Success SnackBar displays "Report submitted successfully"
- Database contains new report record with correct data
- Report ID is returned from API

### 2. Image Upload with Report

**Test Steps:**

1. Open ReportingDialog
2. Tap "Add Photo" button
3. Select test image from assets
4. Adjust occupancy count
5. Tap "Submit" button
6. Verify upload progress indicator appears
7. Wait for upload to complete
8. Verify success message

**Expected Results:**

- Upload progress bar shows 0% → 100%
- Image is uploaded to backend storage
- Image URL is returned and associated with report
- Database contains image_url field populated

### 3. Network Error Handling

**Test Steps:**

1. Stop backend server temporarily
2. Open ReportingDialog
3. Attempt to submit report
4. Verify error message appears
5. Tap "Retry" button
6. Restart backend server
7. Verify retry succeeds

**Expected Results:**

- Error message displays: "Failed to submit report: Network error"
- Retry button is visible
- After retry, report submits successfully

### 4. API Validation Errors

**Test Steps:**

1. Open ReportingDialog
2. Set invalid occupancy count (e.g., -1 or > capacity)
3. Tap "Submit" button
4. Verify validation error from API

**Expected Results:**

- Error message displays API validation error
- Report is not saved to database
- User can correct and resubmit

### 5. Authentication Token Expiration

**Test Steps:**

1. Authenticate user
2. Manually expire JWT token
3. Attempt to submit report
4. Verify 401 error handling

**Expected Results:**

- App detects 401 Unauthorized
- User is redirected to login screen
- Error message explains token expired

## Database Verification

### Test Helper: Database Query

```dart
import 'package:mysql1/mysql1.dart';

class TestDatabaseHelper {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: '192.168.1.67',
      port: 3306,
      user: 'test_user',
      password: 'test_password',
      db: 'motorbike_parking_app_test',
    );
    return await MySqlConnection.connect(settings);
  }

  static Future<Map<String, dynamic>?> getReportById(String reportId) async {
    final conn = await connect();
    final results = await conn.query(
      'SELECT * FROM user_reports WHERE id = ?',
      [reportId],
    );
    await conn.close();

    if (results.isEmpty) return null;

    final row = results.first;
    return {
      'id': row['id'],
      'spot_id': row['spot_id'],
      'user_id': row['user_id'],
      'reported_count': row['reported_count'],
      'user_latitude': row['user_latitude'],
      'user_longitude': row['user_longitude'],
      'image_url': row['image_url'],
      'created_at': row['created_at'],
    };
  }

  static Future<void> cleanupTestData() async {
    final conn = await connect();
    await conn.query('DELETE FROM user_reports WHERE user_id LIKE "test_%"');
    await conn.close();
  }
}
```

## Test Data Setup

### Test User Account

Create a test user in the database:

```sql
INSERT INTO users (id, email, password_hash, is_anonymous, created_at)
VALUES (
  'test_user_123',
  'test@example.com',
  '$2b$10$...',  -- bcrypt hash of 'TestPassword123'
  0,
  NOW()
);
```

### Test Parking Zone

Ensure test parking zone exists:

```sql
INSERT INTO parking_zones (id, google_places_id, latitude, longitude, total_capacity, current_occupancy, confidence_score, last_updated)
VALUES (
  'test_zone_123',
  'ChIJTest123',
  38.7223,
  -9.1393,
  10,
  5,
  0.8,
  NOW()
);
```

## Running Integration Tests

### Command

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test file
flutter test integration_test/reporting_dialog_integration_test.dart

# Run with verbose output
flutter test integration_test/ --verbose
```

### Prerequisites Checklist

Before running tests:

- [ ] Backend server is running (`cd backend && npm run dev`)
- [ ] Database is accessible and seeded with test data
- [ ] Test user account exists
- [ ] Test parking zones exist
- [ ] `.env` file has correct test API URL

## Test Configuration

### `integration_test/config.dart`

```dart
class IntegrationTestConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'TEST_API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'TestPassword123';
  static const String testZoneId = 'test_zone_123';

  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration testTimeout = Duration(seconds: 30);
}
```

## Success Criteria

Task 15.2 is complete when:

1. ✅ Integration test file created at `integration_test/reporting_dialog_integration_test.dart`
2. ✅ Test helper for database verification implemented
3. ✅ All 5 test scenarios pass consistently
4. ✅ Tests verify actual data persistence in MariaDB
5. ✅ Tests run successfully against local backend
6. ✅ Tests run successfully against Raspberry Pi backend
7. ✅ Test cleanup properly removes test data
8. ✅ Documentation updated with test running instructions

## Benefits of Integration Testing Approach

### Advantages

1. **Real-world validation**: Tests actual integration between app and backend
2. **Database verification**: Confirms data is correctly persisted
3. **Network behavior**: Tests real HTTP requests and responses
4. **API contract validation**: Ensures Flutter app and API are compatible
5. **End-to-end confidence**: Provides confidence in the full stack

### Limitations

1. **Slower execution**: Integration tests take longer than unit tests
2. **Environment dependency**: Requires backend server to be running
3. **Test data management**: Requires careful cleanup of test data
4. **Flakiness potential**: Network issues can cause test failures

## Maintenance

### Test Data Cleanup

After each test run:

```sql
DELETE FROM user_reports WHERE user_id = 'test_user_123' AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);
DELETE FROM report_images WHERE report_id IN (SELECT id FROM user_reports WHERE user_id = 'test_user_123');
```

### Backend Test Mode

Consider adding a test mode to backend:

```javascript
// backend/src/config/environment.js
const isTestMode = process.env.NODE_ENV === "test";

if (isTestMode) {
  // Use test database
  // Disable rate limiting
  // Enable test endpoints
}
```

## Next Steps

1. Create `integration_test/` directory
2. Add `integration_test` package to `pubspec.yaml`
3. Implement test helper for database queries
4. Write first integration test for report submission
5. Add remaining test scenarios
6. Document test running procedure
7. Add integration tests to CI/CD pipeline (future)

## References

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Backend API Documentation](../backend/README.md)
- [Database Schema](../schema.sql)
- [Task 15 Requirements](.kiro/specs/flutter-api-migration/requirements.md)
