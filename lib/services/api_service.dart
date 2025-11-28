import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';
import 'logger_service.dart';

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
    // Backend returns: { token: "...", user: { id: "...", email: "..." } }
    final user = json['user'] as Map<String, dynamic>?;
    return AuthResponse(
      token: json['token'] as String,
      userId: user?['id'] as String? ?? '',
      email: user?['email'] as String?,
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
    final baseUrl = Environment.apiBaseUrl;
    print('=== API SERVICE INITIALIZATION ===');
    print('Base URL: $baseUrl');
    print('Environment: ${Environment.currentEnvironment}');
    print('Timeout: ${Environment.apiTimeout}ms');
    print('==================================');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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

          // Log request using LoggerService
          final url = '${options.baseUrl}${options.path}';
          LoggerService.logNetworkRequest(
            options.method,
            url,
            body: options.data is Map<String, dynamic> ? options.data : null,
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response using LoggerService
          final url = '${response.requestOptions.baseUrl}${response.requestOptions.path}';
          LoggerService.logNetworkResponse(
            response.statusCode ?? 0,
            url,
            body: response.data,
          );

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Log network error using LoggerService
          final url = '${error.requestOptions.baseUrl}${error.requestOptions.path}';
          LoggerService.logNetworkError(url, error);

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
      print('[API] Signing up user: $email');
      print('[API] POST ${Environment.apiBaseUrl}/api/auth/register');
      final response = await post(
        '/api/auth/register',
        body: {
          'email': email,
          'password': password,
        },
      );

      print('[API] Sign up response status: ${response.statusCode}');
      print('[API] Sign up response data: ${response.data}');
      
      final authResponse = AuthResponse.fromJson(response.data);
      await saveToken(authResponse.token);

      return authResponse;
    } catch (e) {
      print('[API] Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in an existing user with email and password
  /// Returns AuthResponse containing JWT token and user information
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('[API] Signing in user: $email');
      print('[API] POST ${Environment.apiBaseUrl}/api/auth/login');
      final response = await post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      print('[API] Sign in response status: ${response.statusCode}');
      print('[API] Sign in response data: ${response.data}');
      final authResponse = AuthResponse.fromJson(response.data);
      await saveToken(authResponse.token);

      return authResponse;
    } catch (e) {
      print('[API] Sign in error: $e');
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
      // Log complete URL (baseUrl + endpoint)
      final fullUrl = '${_dio.options.baseUrl}$path';
      LoggerService.debug(
        'API GET: $fullUrl',
        component: 'ApiService',
      );

      // Log authentication header presence (without exposing token value)
      final hasAuthHeader = _dio.options.headers.containsKey('Authorization');
      LoggerService.debug(
        'Auth header: ${hasAuthHeader ? 'present' : 'missing'}',
        component: 'ApiService',
      );

      // Log request timeout configuration
      LoggerService.debug(
        'Request timeout: ${_dio.options.connectTimeout?.inSeconds}s, Receive timeout: ${_dio.options.receiveTimeout?.inSeconds}s',
        component: 'ApiService',
      );

      // Perform the GET request
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
      );

      // Log response status code before returning
      LoggerService.debug(
        'Response status: ${response.statusCode}',
        component: 'ApiService',
      );

      // Log response data structure type
      LoggerService.debug(
        'Response data type: ${response.data.runtimeType}',
        component: 'ApiService',
      );

      return response;
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
