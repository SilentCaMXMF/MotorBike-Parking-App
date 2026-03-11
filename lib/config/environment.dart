import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum EnvironmentType {
  development,
  staging,
  production,
}

class Environment {
  static EnvironmentType _currentEnvironment = EnvironmentType.development;

  static Map<String, String?> get _env {
    if (kIsWeb) {
      return _loadWebEnv();
    }
    return dotenv.env;
  }

  static Map<String, String?> _loadWebEnv() {
    // On web, use hardcoded fallback values (same as Vercel env vars)
    // These match the values set in Vercel dashboard
    return {
      'DEV_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
      'PROD_API_BASE_URL': 'https://homelab-backendpi.pedroocalado.eu',
      'ENVIRONMENT': 'development',
      'GOOGLE_MAPS_API_KEY': 'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ',
      'API_TIMEOUT': '30000',
    };
  }

  static String get apiBaseUrl {
    final env = _env;
    switch (_currentEnvironment) {
      case EnvironmentType.development:
        return env['DEV_API_BASE_URL'] ??
            'https://homelab-backendpi.pedroocalado.eu';
      case EnvironmentType.staging:
        return env['STAGING_API_BASE_URL'] ?? 'http://staging.example.com';
      case EnvironmentType.production:
        return env['PROD_API_BASE_URL'] ??
            'https://homelab-backendpi.pedroocalado.eu';
    }
  }

  static int get apiTimeout {
    final env = _env;
    return int.tryParse(env['API_TIMEOUT'] ?? '30000') ?? 30000;
  }

  static String get googleMapsApiKey {
    final env = _env;
    return env['GOOGLE_MAPS_API_KEY'] ??
        'AIzaSyCj7NygIqVX9qpdYhtmiksowqfjOHyHshQ';
  }

  static EnvironmentType get currentEnvironment => _currentEnvironment;

  static void setEnvironment(EnvironmentType env) {
    _currentEnvironment = env;
  }

  static Future<void> initialize() async {
    if (!kIsWeb) {
      await dotenv.load(fileName: '.env');
    }

    String envString;
    if (kIsWeb) {
      envString = _env['ENVIRONMENT'] ?? 'development';
    } else {
      envString = dotenv.env['ENVIRONMENT'] ?? 'development';
    }

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
