/// Utility class for converting technical errors to user-friendly messages
class ErrorMessages {
  /// Convert any error to a user-friendly message
  static String getFriendlyMessage(dynamic error) {
    final String errorString = error.toString().toLowerCase();

    // Connection errors
    if (errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('token')) {
      return 'Session expired. Please log in again.';
    }

    // Server errors
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Server error. Please try again later.';
    }

    // Not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Resource not found. Please try again.';
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied. Please check your settings.';
    }

    // Location errors
    if (errorString.contains('location')) {
      return 'Unable to get your location. Please enable location services.';
    }

    // Default message
    return 'Something went wrong. Please try again.';
  }

  /// Get a friendly message for specific error types
  static String getLocationError() {
    return 'Unable to get your location. Please enable location services in your device settings.';
  }

  static String getNetworkError() {
    return 'No internet connection. Please check your network settings.';
  }

  static String getServerError() {
    return 'Server is temporarily unavailable. Please try again later.';
  }

  static String getAuthError() {
    return 'Your session has expired. Please log in again.';
  }
}
