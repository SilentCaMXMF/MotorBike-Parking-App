/// Integration test configuration
/// 
/// This file contains configuration values for integration tests that connect
/// to the actual backend API and database.
class IntegrationTestConfig {
  /// API base URL - can be overridden with environment variable
  static const String apiBaseUrl = String.fromEnvironment(
    'TEST_API_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Test user credentials
  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'TestPassword123';

  /// Test parking zone ID (must exist in test database)
  static const String testZoneId = 'test_zone_123';

  /// Test timeouts
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration testTimeout = Duration(seconds: 30);

  /// Database connection settings (for verification)
  static const String dbHost = String.fromEnvironment(
    'TEST_DB_HOST',
    defaultValue: '192.168.1.67',
  );
  static const int dbPort = 3306;
  static const String dbName = String.fromEnvironment(
    'TEST_DB_NAME',
    defaultValue: 'motorbike_parking_app',
  );
  static const String dbUser = String.fromEnvironment(
    'TEST_DB_USER',
    defaultValue: 'motorbike_app',
  );
  static const String dbPassword = String.fromEnvironment(
    'TEST_DB_PASSWORD',
    defaultValue: '',
  );
}
