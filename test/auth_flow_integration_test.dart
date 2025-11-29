import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motorbike_parking_app/screens/auth_screen.dart';
import 'package:motorbike_parking_app/services/auth_service.dart';
import '../mocks/mock_auth_service.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  group('AuthScreen Integration Tests', () {
    testWidgets('successful sign up flow', (WidgetTester tester) async {
      // Setup mock to succeed
      mockAuthService.setupSignUpSuccess();
      mockAuthService.setupDefaults();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(authService: mockAuthService),
        ),
      );

      // Verify initial state
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Enter valid credentials
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password123');

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify success (would navigate away in real app)
      // In test, we can't easily verify navigation, but ensure no error
      expect(find.text('Sign Up'), findsNothing); // Should navigate away
    });

    testWidgets('successful sign in flow', (WidgetTester tester) async {
      // Setup mock to succeed
      mockAuthService.setupSignInSuccess();
      mockAuthService.setupDefaults();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(authService: mockAuthService),
        ),
      );

      // Switch to sign in mode
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Sign In'), findsOneWidget);

      // Enter credentials
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('sign up validation errors', (WidgetTester tester) async {
      mockAuthService.setupDefaults();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(authService: mockAuthService),
        ),
      );

      // Test empty email
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.enterText(find.byType(TextField).at(1), 'Password123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Please enter your email address'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Test weak password
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'),
          findsOneWidget);

      // Test missing uppercase
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Password must contain at least one uppercase letter'),
          findsOneWidget);

      // Test missing number
      await tester.enterText(find.byType(TextField).at(1), 'Password');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Password must contain at least one number'),
          findsOneWidget);
    });

    testWidgets('sign in validation errors', (WidgetTester tester) async {
      mockAuthService.setupDefaults();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(authService: mockAuthService),
        ),
      );

      // Switch to sign in
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Test empty email
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email address'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextField).at(0), 'invalid');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Test short password
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'),
          findsOneWidget);
    });

    testWidgets('Firebase auth errors are displayed',
        (WidgetTester tester) async {
      // Setup sign up to fail
      mockAuthService.setupSignUpFailure(
        FirebaseAuthException(
            code: 'email-already-in-use', message: 'Email already exists'),
      );
      mockAuthService.setupDefaults();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(authService: mockAuthService),
        ),
      );

      // Enter valid credentials
      await tester.enterText(
          find.byType(TextField).at(0), 'existing@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password123');

      // Tap sign up
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Verify error message
      expect(find.text('An account already exists with this email.'),
          findsOneWidget);
    });

    testWidgets('anonymous sign in flow', (WidgetTester tester) async {
      mockAuthService.setupAnonymousSignInSuccess();
      mockAuthService.setupDefaults();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(authService: mockAuthService),
        ),
      );

      // Tap continue as guest
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Verify success (should navigate away)
      expect(find.text('Continue as Guest'), findsNothing);
    });
  });
}
