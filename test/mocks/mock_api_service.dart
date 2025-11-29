import 'dart:io';
import 'package:dio/dio.dart';
import '../../lib/services/api_service.dart';

/// Mock API Service for testing
/// Provides configurable responses for all API methods
class MockApiService implements ApiService {
  AuthResponse? _signUpResponse;
  Exception? _signUpException;
  AuthResponse? _signInResponse;
  Exception? _signInException;
  AuthResponse? _signInAnonymouslyResponse;
  Exception? _signInAnonymouslyException;

  final Map<String, Response> _getResponses = {};
  final Map<String, DioException> _getExceptions = {};
  final Map<String, Response> _postResponses = {};
  final Map<String, DioException> _postExceptions = {};
  final Map<String, Response> _uploadResponses = {};
  final Map<String, DioException> _uploadExceptions = {};

  // ============================================================================
  // AUTHENTICATION MOCK RESPONSES
  // ============================================================================

  /// Setup successful sign up response
  void setupSignUpSuccess({
    String token = 'test-token-123',
    String userId = 'user-123',
    String? email,
  }) {
    _signUpResponse = AuthResponse(
      token: token,
      userId: userId,
      email: email,
    );
    _signUpException = null;
  }

  /// Setup sign up failure
  void setupSignUpFailure(Exception exception) {
    _signUpException = exception;
    _signUpResponse = null;
  }

  @override
  Future<AuthResponse> signUp(String email, String password) async {
    if (_signUpException != null) {
      throw _signUpException!;
    }
    return _signUpResponse!;
  }

  /// Setup successful sign in response
  void setupSignInSuccess({
    String token = 'test-token-123',
    String userId = 'user-123',
    String? email,
  }) {
    _signInResponse = AuthResponse(
      token: token,
      userId: userId,
      email: email,
    );
    _signInException = null;
  }

  /// Setup sign in failure
  void setupSignInFailure(Exception exception) {
    _signInException = exception;
    _signInResponse = null;
  }

  @override
  Future<AuthResponse> signIn(String email, String password) async {
    if (_signInException != null) {
      throw _signInException!;
    }
    return _signInResponse!;
  }

  /// Setup successful anonymous sign in response
  void setupSignInAnonymouslySuccess({
    String token = 'test-anon-token-123',
    String userId = 'anon-user-123',
  }) {
    _signInAnonymouslyResponse = AuthResponse(
      token: token,
      userId: userId,
    );
    _signInAnonymouslyException = null;
  }

  /// Setup anonymous sign in failure
  void setupSignInAnonymouslyFailure(Exception exception) {
    _signInAnonymouslyException = exception;
    _signInAnonymouslyResponse = null;
  }

  @override
  Future<AuthResponse> signInAnonymously() async {
    if (_signInAnonymouslyException != null) {
      throw _signInAnonymouslyException!;
    }
    return _signInAnonymouslyResponse!;
  }

  // ============================================================================
  // HTTP METHOD MOCK RESPONSES
  // ============================================================================

  /// Setup successful GET request response
  void setupGetSuccess(String path, Map<String, dynamic> responseData) {
    _getResponses[path] = Response(
      requestOptions: RequestOptions(path: path),
      data: responseData,
      statusCode: 200,
    );
    _getExceptions.remove(path);
  }

  /// Setup GET request failure
  void setupGetFailure(String path, DioException exception) {
    _getExceptions[path] = exception;
    _getResponses.remove(path);
  }

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    if (_getExceptions.containsKey(path)) {
      throw _getExceptions[path]!;
    }
    return _getResponses[path]!;
  }

  /// Setup successful POST request response
  void setupPostSuccess(String path, Map<String, dynamic> responseData) {
    _postResponses[path] = Response(
      requestOptions: RequestOptions(path: path),
      data: responseData,
      statusCode: 200,
    );
    _postExceptions.remove(path);
  }

  /// Setup POST request failure
  void setupPostFailure(String path, DioException exception) {
    _postExceptions[path] = exception;
    _postResponses.remove(path);
  }

  @override
  Future<Response> post(String path, {dynamic body}) async {
    if (_postExceptions.containsKey(path)) {
      throw _postExceptions[path]!;
    }
    return _postResponses[path]!;
  }

  /// Setup successful PUT request response
  void setupPutSuccess(String path, Map<String, dynamic> responseData) {
    _postResponses[path] = Response(
      requestOptions: RequestOptions(path: path),
      data: responseData,
      statusCode: 200,
    );
  }

  @override
  Future<Response> put(String path, {dynamic body}) async {
    if (_postExceptions.containsKey(path)) {
      throw _postExceptions[path]!;
    }
    return _postResponses[path]!;
  }

  @override
  Future<Response> delete(String path) async {
    if (_getExceptions.containsKey(path)) {
      throw _getExceptions[path]!;
    }
    return _getResponses[path]!;
  }

  /// Setup successful file upload response
  void setupUploadFileSuccess(
    String path,
    Map<String, dynamic> responseData,
  ) {
    _uploadResponses[path] = Response(
      requestOptions: RequestOptions(path: path),
      data: responseData,
      statusCode: 200,
    );
    _uploadExceptions.remove(path);
  }

  /// Setup file upload failure
  void setupUploadFileFailure(String path, DioException exception) {
    _uploadExceptions[path] = exception;
    _uploadResponses.remove(path);
  }

  @override
  Future<Response> uploadFile(
    String path,
    File file, {
    Map<String, dynamic>? fields,
    Function(double)? onProgress,
  }) async {
    if (_uploadExceptions.containsKey(path)) {
      throw _uploadExceptions[path]!;
    }
    return _uploadResponses[path]!;
  }

  // ============================================================================
  // TOKEN MANAGEMENT MOCK RESPONSES
  // ============================================================================

  String? _savedToken;

  @override
  Future<void> saveToken(String token) async {
    _savedToken = token;
  }

  @override
  Future<String?> getToken() async {
    return _savedToken;
  }

  @override
  Future<void> clearToken() async {
    _savedToken = null;
  }

  @override
  Future<void> signOut() async {
    await clearToken();
  }
}
