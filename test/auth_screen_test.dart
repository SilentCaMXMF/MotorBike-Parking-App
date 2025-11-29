import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:motorbike_parking_app/screens/auth_screen.dart';
import 'package:motorbike_parking_app/services/api_service.dart';

// Generate mock using mockito
@GenerateMocks([ApiService])
import 'auth_screen_test.mocks.dart';

void main() {
  group('AuthScreen', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('renders sign in form initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('switches to sign up form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows validation error for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'),
          findsOneWidget);
    });

    testWidgets('shows loading indicator during sign in',
        (WidgetTester tester) async {
      when(mockApiService.signIn(any, any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => AuthResponse(token: 'test-token', userId: 'user-123'),
        ),
      );
      when(mockApiService.saveToken(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls signIn API on successful form submission',
        (WidgetTester tester) async {
      when(mockApiService.signIn(any, any)).thenAnswer(
        (_) async => AuthResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
        ),
      );
      when(mockApiService.saveToken(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      verify(mockApiService.signIn('test@example.com', 'password123'))
          .called(1);
      verify(mockApiService.saveToken('test-token')).called(1);
    });

    testWidgets('shows error message on sign in failure',
        (WidgetTester tester) async {
      when(mockApiService.signIn(any, any)).thenThrow(
        Exception('Invalid credentials'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows loading indicator during sign up',
        (WidgetTester tester) async {
      when(mockApiService.signUp(any, any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => AuthResponse(token: 'test-token', userId: 'user-123'),
        ),
      );
      when(mockApiService.saveToken(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      // Switch to sign up mode
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'Password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls signUp API on successful form submission',
        (WidgetTester tester) async {
      when(mockApiService.signUp(any, any)).thenAnswer(
        (_) async => AuthResponse(
          token: 'test-token',
          userId: 'user-123',
          email: 'test@example.com',
        ),
      );
      when(mockApiService.saveToken(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      // Switch to sign up mode
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'Password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      verify(mockApiService.signUp('test@example.com', 'Password123'))
          .called(1);
      verify(mockApiService.saveToken('test-token')).called(1);
    });

    testWidgets('shows error message on sign up failure',
        (WidgetTester tester) async {
      when(mockApiService.signUp(any, any)).thenThrow(
        Exception('Email already exists'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      // Switch to sign up mode
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'Password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Email already exists'), findsOneWidget);
    });

    testWidgets('shows validation error for sign up password without uppercase',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      // Switch to sign up mode
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      expect(find.text('Password must contain at least one uppercase letter'),
          findsOneWidget);
    });

    testWidgets('calls signInAnonymously on guest button tap',
        (WidgetTester tester) async {
      when(mockApiService.signInAnonymously()).thenAnswer(
        (_) async => AuthResponse(
          token: 'anon-token',
          userId: 'anon-user-123',
        ),
      );
      when(mockApiService.saveToken(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.tap(find.text('Continue as Guest'));
      await tester.pump();

      verify(mockApiService.signInAnonymously()).called(1);
      verify(mockApiService.saveToken('anon-token')).called(1);
    });

    testWidgets('shows error message on anonymous authentication failure',
        (WidgetTester tester) async {
      when(mockApiService.signInAnonymously()).thenThrow(
        Exception('Anonymous authentication disabled'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Anonymous authentication disabled'),
          findsOneWidget);
    });

    testWidgets('disables button while loading', (WidgetTester tester) async {
      when(mockApiService.signIn(any, any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => AuthResponse(token: 'test-token', userId: 'user-123'),
        ),
      );
      when(mockApiService.saveToken(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(apiService: mockApiService),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Try to tap Continue as Guest button while loading
      final guestButton = find.widgetWithText(TextButton, 'Continue as Guest');
      expect(guestButton, findsOneWidget);

      final button = tester.widget<TextButton>(guestButton);
      expect(button.onPressed, isNull);
    });
  });
}
