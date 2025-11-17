import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// LoggerService provides structured logging for the Motorbike Parking App
/// with component tagging and build-type conditional logging.
class LoggerService {
  static const String _tag = 'MotorbikeParking';

  /// Log a debug message with optional component tag
  /// Only logs in debug and profile modes
  static void debug(String message, {String? component}) {
    if (kDebugMode || kProfileMode) {
      final prefix = component != null ? '[$component]' : '';
      developer.log(
        '$prefix $message',
        name: _tag,
        level: 500, // Debug level
      );
    }
  }

  /// Log an info message with optional component tag
  /// Only logs in debug and profile modes
  static void info(String message, {String? component}) {
    if (kDebugMode || kProfileMode) {
      final prefix = component != null ? '[$component]' : '';
      developer.log(
        '$prefix $message',
        name: _tag,
        level: 800, // Info level
      );
    }
  }

  /// Log a warning message with optional component tag
  /// Logs in all build modes
  static void warning(String message, {String? component}) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 900, // Warning level
    );
  }

  /// Log an error message with optional error object, stack trace, and component tag
  /// Logs in all build modes
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? component,
  }) {
    final prefix = component != null ? '[$component]' : '';
    developer.log(
      '$prefix $message',
      name: _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an HTTP request with method, URL, and optional body
  /// Only logs in debug and profile modes
  static void logNetworkRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    if (kDebugMode || kProfileMode) {
      final bodyInfo = body != null ? ' with body' : '';
      info('HTTP $method $url$bodyInfo', component: 'Network');
    }
  }

  /// Log an HTTP response with status code, URL, and optional body
  /// Only logs in debug and profile modes
  static void logNetworkResponse(
    int statusCode,
    String url, {
    dynamic body,
  }) {
    if (kDebugMode || kProfileMode) {
      info('HTTP Response $statusCode from $url', component: 'Network');
    }
  }

  /// Log a network error with URL and error object
  /// Logs in all build modes
  static void logNetworkError(String url, Object error) {
    LoggerService.error(
      'Network error for $url',
      error: error,
      component: 'Network',
    );
  }
}
