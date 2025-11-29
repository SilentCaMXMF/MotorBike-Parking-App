// import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase Authentication operations.
/// Provides methods for sign up, sign in, sign out, and anonymous authentication.
// ============================================================================
// FIREBASE SERVICE - COMMENTED OUT FOR API MIGRATION
// ============================================================================
// This service is preserved for potential scaling back to Firebase if the local
// Raspberry Pi backend reaches capacity limits.
//
// The app has been migrated to use a custom REST API backend with MariaDB
// instead of Firebase Authentication. This service is kept in the project to enable
// quick rollback if needed.
//
// CURRENT STATUS: Inactive (commented out)
// MIGRATION DATE: November 2025
// REASON: Cost reduction and data ownership via local backend
// ============================================================================
/*
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently authenticated user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Creates a new user account with email and password.
  /// Throws an Exception with user-friendly message on failure.
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('Password is too weak. Please choose a stronger password.');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled.');
        default:
          throw Exception('Sign up failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  /// Signs in an existing user with email and password.
  /// Throws an Exception with user-friendly message on failure.
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        case 'user-not-found':
          throw Exception('No account found with this email.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Anonymous sign in (for quick reporting without account)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw Exception('Anonymous sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during anonymous sign in.');
    }
  }
}
*/
