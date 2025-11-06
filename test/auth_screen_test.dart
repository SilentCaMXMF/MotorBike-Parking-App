import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorbike_parking_app/screens/auth_screen.dart';

void main() {
  group('AuthScreen', () {
    testWidgets('renders sign in form initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets('switches to sign up form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });
}