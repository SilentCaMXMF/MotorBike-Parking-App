import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:motorbike_parking_app/services/api_service.dart';
import 'mocks/mock_api_service.dart';

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  group('ApiService Authentication Methods', () {
    test('signUp success returns AuthResponse with token', () async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'password123';
      const expectedToken = 'test-jwt-token';
      const expectedUserId = 'user-123';

      mockApiService.setupSignUpSuccess(
        token: expectedToken,
        userId: expectedUserId,
        email: testEmail,
      );

      // Act
      final result = await mockApiService.signUp(testEmail, testPassword);

      // Assert
      expect(result.token, expectedToken);
      expect(result.userId, expectedUserId);
      expect(result.email, testEmail);
    });

    test('signUp failure throws exception', () async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'password123';
      final exception = Exception('Email already exists');

      mockApiService.setupSignUpFailure(exception);

      // Act & Assert
      expect(
        () => mockApiService.signUp(testEmail, testPassword),
        throwsA(isA<Exception>()),
      );
    });

    test('signIn success returns AuthResponse with token', () async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'password123';
      const expectedToken = 'test-jwt-token';
      const expectedUserId = 'user-123';

      mockApiService.setupSignInSuccess(
        token: expectedToken,
        userId: expectedUserId,
        email: testEmail,
      );

      // Act
      final result = await mockApiService.signIn(testEmail, testPassword);

      // Assert
      expect(result.token, expectedToken);
      expect(result.userId, expectedUserId);
      expect(result.email, testEmail);
    });

    test('signIn failure throws exception', () async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'wrongpassword';
      final exception = Exception('Invalid credentials');

      mockApiService.setupSignInFailure(exception);

      // Act & Assert
      expect(
        () => mockApiService.signIn(testEmail, testPassword),
        throwsA(isA<Exception>()),
      );
    });

    test('signInAnonymously success returns AuthResponse with token', () async {
      // Arrange
      const expectedToken = 'test-anon-token';
      const expectedUserId = 'anon-user-123';

      mockApiService.setupSignInAnonymouslySuccess(
        token: expectedToken,
        userId: expectedUserId,
      );

      // Act
      final result = await mockApiService.signInAnonymously();

      // Assert
      expect(result.token, expectedToken);
      expect(result.userId, expectedUserId);
    });

    test('signInAnonymously failure throws exception', () async {
      // Arrange
      final exception = Exception('Anonymous login disabled');

      mockApiService.setupSignInAnonymouslyFailure(exception);

      // Act & Assert
      expect(
        () => mockApiService.signInAnonymously(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
