import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';

/// Response model for authentication operations
class AuthResponse {
  final String token;
  final String userId;
  final String? email;

  AuthResponse({
    required this.token,
    required this.userId,
    this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String?,
    );
  }
}

/// API Service class for handling all HTTP communication with the backend
/// Implements singleton pattern for consistent instance usage across the app
class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';

  // Singleton pattern implementation
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal() {
    _initializeDio();
  }

  /// Initialize Dio client with base URL and configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: Duration(milliseconds: Environment.apiTimeout),
        receiveTimeout: Duration(milliseconds: Environment.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Setup request and response interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach JWT token to authenticated requests
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request in debug mode
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          print('REQUEST HEADERS: ${options.headers}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response in debug mode
          print(
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          print('RESPONSE DATA: ${response.data}');

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Handle token expiration (401 Unauthorized)
          if (error.response?.statusCode == 401) {
            await clearToken();
            // Token expired or invalid - user needs to re-authenticate
          }

          // Transform error to user-friendly message
          final transformedError = _transformError(error);
          return handler.reject(transformedError);
        },
      ),
    );
  }

  /// Transform DioException to user-friendly error messages
  DioException _transformError(DioException error) {
    String friendlyMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        friendlyMessage =
            'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        friendlyMessage = 'Request timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        friendlyMessage =
            'Server is taking too long to respond. Please try again.';
        break;
      case DioExceptionType.badResponse:
        friendlyMessage = _handleResponseError(error.response);
        break;
      case DioExceptionType.cancel:
        friendlyMessage = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        friendlyMessage =
            'Connection error. Please check your internet connection.';
        break;
      default:
        friendlyMessage = 'An unexpected error occurred. Please try again.';
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: friendlyMessage,
    );
  }

  /// Handle HTTP response errors with user-friendly messages
  String _handleResponseError(Response? response) {
    if (response == null) {
      return 'No response from server. Please try again.';
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // Try to extract error message from response
    String? errorMessage;
    if (data is Map<String, dynamic>) {
      errorMessage = data['error'] as String? ??
          data['message'] as String? ??
          data['msg'] as String?;
    }

    switch (statusCode) {
      case 400:
        return 'Invalid request: ${errorMessage ?? "Please check your input"}';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return errorMessage ?? 'Conflict: Resource already exists.';
      case 422:
        return 'Validation error: ${errorMessage ?? "Invalid data provided"}';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return errorMessage ?? 'An error occurred. Please try again.';
    }
  }

  // ============================================================================
  // TOKEN MANAGEMENT METHODS
  // ============================================================================

  /// Save JWT token to secure storage
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Retrieve JWT token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Clear JWT token from secure storage (logout)
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Sign up a new user with email and password
  /// Returns AuthResponse containing JWT token and user information
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await post(
        '/api/auth/register',
        body: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      await saveToken(authResponse.token);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in an existing user with email and password
  /// Returns AuthResponse containing JWT token and user information
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      await saveToken(authResponse.token);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in anonymously without email/password
  /// Returns AuthResponse containing JWT token for anonymous user
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await post('/api/auth/anonymous');

      final authResponse = AuthResponse.fromJson(response.data['data']);
      await saveToken(authResponse.token);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out the current user
  /// Clears JWT token and optionally calls logout endpoint
  Future<void> signOut() async {
    try {
      // Call logout endpoint if token exists
      final token = await getToken();
      if (token != null) {
        try {
          await post('/api/auth/logout');
        } catch (e) {
          // Continue with local logout even if API call fails
          print('Logout API call failed: $e');
        }
      }
    } finally {
      // Always clear token locally
      await clearToken();
    }
  }

  // ============================================================================
  // GENERIC HTTP METHODS
  // ============================================================================

  /// Perform GET request with optional query parameters
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParams,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Perform POST request with optional request body
  Future<Response> post(
    String path, {
    dynamic body,
  }) async {
    try {
      return await _dio.post(
        path,
        data: body,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Perform PUT request with optional request body
  Future<Response> put(
    String path, {
    dynamic body,
  }) async {
    try {
      return await _dio.put(
        path,
        data: body,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Perform DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file using multipart form data with progress tracking
  ///
  /// [path] - API endpoint path
  /// [file] - File to upload
  /// [fields] - Additional form fields to include
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  Future<Response> uploadFile(
    String path,
    File file, {
    Map<String, dynamic>? fields,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        ...?fields,
      });

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            onProgress(progress);
          }
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
