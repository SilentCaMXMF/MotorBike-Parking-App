import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:motorbike_parking_app/services/auth_service.dart';

// Mock FirebaseAuth
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// Mock User
class MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-id';

  @override
  String? get email => 'test@example.com';
}

// Mock UserCredential
class MockUserCredential extends Mock implements UserCredential {
  @override
  User get user => MockUser();
}

// Mock AuthService
class MockAuthService extends Mock implements AuthService {
  final MockFirebaseAuth _mockAuth = MockFirebaseAuth();
  final MockUser _mockUser = MockUser();

  @override
  Stream<User?> get authStateChanges => Stream.value(_mockUser);

  @override
  User? get currentUser => _mockUser;

  // Setup default behaviors
  void setupDefaults() {
    when(_mockAuth.currentUser).thenReturn(_mockUser);
    when(_mockAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(_mockUser));
  }

  // Setup sign in success
  void setupSignInSuccess() {
    when(_mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => MockUserCredential());
  }

  // Setup sign in failure
  void setupSignInFailure(FirebaseAuthException exception) {
    when(_mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenThrow(exception);
  }

  // Setup sign up success
  void setupSignUpSuccess() {
    when(_mockAuth.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => MockUserCredential());
  }

  // Setup sign up failure
  void setupSignUpFailure(FirebaseAuthException exception) {
    when(_mockAuth.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenThrow(exception);
  }

  // Setup anonymous sign in
  void setupAnonymousSignInSuccess() {
    when(_mockAuth.signInAnonymously())
        .thenAnswer((_) async => MockUserCredential());
  }

  // Setup sign out
  void setupSignOutSuccess() {
    when(_mockAuth.signOut()).thenAnswer((_) async {});
  }

  // Setup no current user
  void setupNoCurrentUser() {
    when(_mockAuth.currentUser).thenReturn(null);
  }
}
