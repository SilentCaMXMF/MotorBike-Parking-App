/// Service for handling Firebase Authentication operations.
/// 
/// NOTE: This service is currently disabled in favor of API-based authentication.
/// To re-enable Firebase Auth:
/// 1. Add firebase_auth to pubspec.yaml dependencies
/// 2. Uncomment the imports in main.dart
/// 3. Re-enable this service
class AuthService {
  static AuthService? _instance;
  
  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }
  
  AuthService._internal();

  bool _isInitialized = false;

  /// Stream of authentication state changes.
  /// Returns an empty stream when Firebase is disabled.
  Stream<dynamic> get authStateChanges {
    _throwIfDisabled();
    return const Stream.empty();
  }

  /// The currently authenticated user, or null if not authenticated.
  dynamic get currentUser {
    _throwIfDisabled();
    return null;
  }

  void _throwIfDisabled() {
    if (!_isInitialized) {
      throw Exception(
        'Firebase Auth is disabled. Using API-based authentication instead.\n'
        'To enable Firebase Auth: add firebase_auth to pubspec.yaml and re-enable in main.dart'
      );
    }
  }

  /// Creates a new user account with email and password.
  Future<dynamic> signUp(String email, String password) async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Auth is disabled');
  }

  /// Signs in an existing user with email and password.
  Future<dynamic> signIn(String email, String password) async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Auth is disabled');
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Auth is disabled');
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Auth is disabled');
  }

  /// Signs in anonymously (for quick reporting without account).
  Future<dynamic> signInAnonymously() async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Auth is disabled');
  }

  /// Initialize the service (call when re-enabling Firebase)
  static Future<void> initialize() async {
    _instance = AuthService._internal();
    _instance!._isInitialized = true;
  }
}
