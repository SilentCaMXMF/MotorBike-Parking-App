import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment types for different deployment scenarios
enum EnvironmentType {
  development,
  staging,
  production,
}

/// Environment configuration for API settings
class Environment {
  static EnvironmentType _currentEnvironment = EnvironmentType.production;

  /// Get the current API base URL based on environment
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case EnvironmentType.development:
        return dotenv.env['DEV_API_BASE_URL'] ?? 'http://localhost:3000';
      case EnvironmentType.staging:
        return dotenv.env['STAGING_API_BASE_URL'] ??
            'http://staging.example.com';
      case EnvironmentType.production:
        return dotenv.env['PROD_API_BASE_URL'] ?? 'http://192.168.1.67:3000';
    }
  }

  /// Get the API timeout in milliseconds
  static int get apiTimeout {
    return int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  }

  /// Get the current environment type
  static EnvironmentType get currentEnvironment => _currentEnvironment;

  /// Set the current environment
  static void setEnvironment(EnvironmentType env) {
    _currentEnvironment = env;
  }

  /// Initialize environment from .env file
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    // Set environment based on ENVIRONMENT variable
    final envString = dotenv.env['ENVIRONMENT'] ?? 'development';
    switch (envString.toLowerCase()) {
      case 'production':
        _currentEnvironment = EnvironmentType.production;
        break;
      case 'staging':
        _currentEnvironment = EnvironmentType.staging;
        break;
      default:
        _currentEnvironment = EnvironmentType.development;
    }
  }
}
