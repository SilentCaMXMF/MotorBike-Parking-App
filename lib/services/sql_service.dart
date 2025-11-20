import 'dart:io';
import 'package:dio/dio.dart';
import '../models/parking_zone.dart';
import '../models/user_report.dart';
import 'api_service.dart';
import 'logger_service.dart';

/// SQL Service class that replaces FirestoreService with API-based implementations
/// Maintains the same method signatures for minimal UI component changes
class SqlService {
  final ApiService _apiService;

  // Singleton pattern implementation
  static final SqlService _instance = SqlService._internal();

  factory SqlService() => _instance;

  SqlService._internal() : _apiService = ApiService();

  // ============================================================================
  // RESPONSE PARSING HELPERS
  // ============================================================================

  /// Extract a list from various response formats
  /// Handles: direct arrays, wrapped responses, and error cases
  List<dynamic> _extractListFromResponse(
    Response response,
    String context,
  ) {
    final responseData = response.data;

    // Log the raw response for debugging
    LoggerService.debug(
      'Raw response type: ${responseData.runtimeType}',
      component: 'SqlService',
    );
    LoggerService.debug(
      'Raw response content: $responseData',
      component: 'SqlService',
    );

    // Handle null response
    if (responseData == null) {
      LoggerService.warning(
        'Received null response for $context',
        component: 'SqlService',
      );
      return [];
    }

    // Handle direct array response
    if (responseData is List) {
      LoggerService.debug(
        'Response is direct array with ${responseData.length} items',
        component: 'SqlService',
      );
      return responseData;
    }

    // Handle wrapped response (Map)
    if (responseData is Map<String, dynamic>) {
      // Check for error field first
      if (responseData.containsKey('error')) {
        final errorMsg = responseData['error'];
        LoggerService.error(
          'API returned error response: $errorMsg',
          component: 'SqlService',
        );
        throw Exception('API:$errorMsg');
      }

      // Try common wrapper keys in order of likelihood
      final possibleKeys = ['data', 'zones', 'parkingZones', 'results'];

      for (final key in possibleKeys) {
        if (responseData.containsKey(key)) {
          final value = responseData[key];

          if (value == null) {
            LoggerService.debug(
              'Found key "$key" but value is null, returning empty list',
              component: 'SqlService',
            );
            return [];
          }

          if (value is List) {
            LoggerService.debug(
              'Extracted list from "$key" field with ${value.length} items',
              component: 'SqlService',
            );
            return value;
          }

          LoggerService.warning(
            'Found key "$key" but value is not a list: ${value.runtimeType}',
            component: 'SqlService',
          );
        }
      }

      // No valid data field found
      LoggerService.error(
        'Response is a Map but contains no valid data field. Keys: ${responseData.keys.toList()}',
        component: 'SqlService',
      );
      throw Exception(
        'PARSING:Invalid response format - expected data field not found',
      );
    }

    // Unexpected response type
    LoggerService.error(
      'Unexpected response type: ${responseData.runtimeType}',
      component: 'SqlService',
    );
    throw Exception(
      'PARSING:Unexpected response format from server',
    );
  }

  /// Extract a single object from various response formats
  /// Handles: direct objects, wrapped responses, and error cases
  Map<String, dynamic>? _extractObjectFromResponse(
    Response response,
    String context,
  ) {
    final responseData = response.data;

    // Log the raw response for debugging
    LoggerService.debug(
      'Raw response type: ${responseData.runtimeType}',
      component: 'SqlService',
    );

    // Handle null response
    if (responseData == null) {
      LoggerService.debug(
        'Received null response for $context',
        component: 'SqlService',
      );
      return null;
    }

    // Handle direct object response
    if (responseData is Map<String, dynamic>) {
      // Check for error field first
      if (responseData.containsKey('error')) {
        final errorMsg = responseData['error'];
        LoggerService.error(
          'API returned error response: $errorMsg',
          component: 'SqlService',
        );
        throw Exception('API:$errorMsg');
      }

      // Check if this is a wrapped response or direct data
      final possibleKeys = ['data', 'zone', 'parkingZone', 'result'];

      for (final key in possibleKeys) {
        if (responseData.containsKey(key)) {
          final value = responseData[key];

          if (value == null) {
            LoggerService.debug(
              'Found key "$key" but value is null',
              component: 'SqlService',
            );
            return null;
          }

          if (value is Map<String, dynamic>) {
            LoggerService.debug(
              'Extracted object from "$key" field',
              component: 'SqlService',
            );
            return value;
          }

          LoggerService.warning(
            'Found key "$key" but value is not an object: ${value.runtimeType}',
            component: 'SqlService',
          );
        }
      }

      // If no wrapper key found, assume the response itself is the data
      // (but only if it doesn't look like a wrapper with count, success, etc.)
      if (!responseData.containsKey('count') &&
          !responseData.containsKey('success') &&
          !responseData.containsKey('message')) {
        LoggerService.debug(
          'Treating entire response as direct object',
          component: 'SqlService',
        );
        return responseData;
      }

      // Has wrapper-like keys but no data field
      LoggerService.warning(
        'Response looks like a wrapper but has no data field. Keys: ${responseData.keys.toList()}',
        component: 'SqlService',
      );
      return null;
    }

    // Unexpected response type
    LoggerService.error(
      'Unexpected response type for object: ${responseData.runtimeType}',
      component: 'SqlService',
    );
    throw Exception(
      'PARSING:Unexpected response format from server',
    );
  }

// ============================================================================
// PARKING ZONE METHODS
// ============================================================================

  /// Get nearby parking zones based on location and radius
  ///
  /// [latitude] - User's current latitude
  /// [longitude] - User's current longitude
  /// [radius] - Search radius in kilometers (default: 5.0)
  /// [limit] - Maximum number of results (default: 50)
  ///
  /// Returns list of ParkingZone objects
  /// Throws Exception with user-friendly message on error
  Future<List<ParkingZone>> getParkingZones({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int limit = 50,
  }) async {
    // Log method entry with all parameters
    LoggerService.debug(
      'Fetching parking zones: lat=$latitude, lng=$longitude, radius=$radius, limit=$limit',
      component: 'SqlService',
    );

    // Log the API endpoint being called
    LoggerService.debug(
      'API call: GET /api/parking/nearby',
      component: 'SqlService',
    );

    // Log query parameters
    final queryParams = {
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
      'limit': limit,
    };
    LoggerService.debug(
      'Query parameters: $queryParams',
      component: 'SqlService',
    );

    try {
      final response = await _apiService.get(
        '/api/parking/nearby',
        queryParams: queryParams,
      );

      // Log response details
      LoggerService.debug(
        'Response received: status=${response.statusCode}',
        component: 'SqlService',
      );

      // Use robust parsing helper
      final dataList = _extractListFromResponse(response, 'getParkingZones');

      // Parse each zone
      final zones = dataList
          .map((json) => ParkingZone.fromJson(json as Map<String, dynamic>))
          .toList();

      // Log number of zones parsed
      LoggerService.debug(
        'Successfully parsed ${zones.length} parking zones',
        component: 'SqlService',
      );

      return zones;
    } on DioException catch (e) {
      // Enhanced error logging with specific error types
      if (e.type == DioExceptionType.connectionTimeout) {
        LoggerService.error(
          'Connection timeout while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'TIMEOUT:Connection timed out. Please check your internet connection and try again.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        LoggerService.error(
          'Receive timeout while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'TIMEOUT:Server took too long to respond. Please try again.');
      } else if (e.type == DioExceptionType.sendTimeout) {
        LoggerService.error(
          'Send timeout while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'TIMEOUT:Request timed out. Please check your connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        LoggerService.error(
          'Connection error while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'NETWORK:Unable to connect to server. Please check your network connection.');
      } else if (e.response?.statusCode == 401) {
        LoggerService.error(
          'Unauthorized (401) while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception('AUTH:Your session has expired. Please log in again.');
      } else if (e.response?.statusCode == 403) {
        LoggerService.error(
          'Forbidden (403) while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception('AUTH:Access denied. Please log in again.');
      } else if (e.response?.statusCode == 404) {
        LoggerService.error(
          'Endpoint not found (404): ${e.requestOptions.path}',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'API:Service endpoint not available. Please contact support.');
      } else if (e.response?.statusCode == 500) {
        LoggerService.error(
          'Server error (500) while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception('API:Server error occurred. Please try again later.');
      } else if (e.response?.statusCode == 503) {
        LoggerService.error(
          'Service unavailable (503) while fetching parking zones',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'API:Service temporarily unavailable. Please try again later.');
      } else {
        LoggerService.error(
          'DioException while fetching parking zones: ${e.type}',
          error: e,
          component: 'SqlService',
        );
        throw Exception(
            'NETWORK:Network error occurred. Please check your connection and try again.');
      }
    } catch (e, stackTrace) {
      LoggerService.error(
        'Unexpected error while fetching parking zones',
        error: e,
        stackTrace: stackTrace,
        component: 'SqlService',
      );
      // Check if it's already a formatted error
      if (e.toString().contains('Exception: ') &&
          (e.toString().contains('AUTH:') ||
              e.toString().contains('NETWORK:') ||
              e.toString().contains('API:') ||
              e.toString().contains('TIMEOUT:') ||
              e.toString().contains('PARSING:'))) {
        rethrow;
      }
      throw Exception(
          'PARSING:Failed to process parking zone data. Please try again.');
    }
  }

  /// Get specific parking zone by ID
  ///
  /// [id] - Parking zone ID
  ///
  /// Returns ParkingZone object or null if not found
  /// Throws Exception with user-friendly message on error
  Future<ParkingZone?> getParkingZone(String id) async {
    try {
      final response = await _apiService.get('/api/parking/$id');

      // Use robust parsing helper
      final data = _extractObjectFromResponse(response, 'getParkingZone');
      if (data == null) {
        return null;
      }

      return ParkingZone.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('AUTH:Your session has expired. Please log in again.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('TIMEOUT:Request timed out. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'NETWORK:Unable to connect to server. Please check your network.');
      }
      throw Exception('API:Failed to fetch parking zone. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception: ') &&
          (e.toString().contains('AUTH:') ||
              e.toString().contains('NETWORK:') ||
              e.toString().contains('API:') ||
              e.toString().contains('TIMEOUT:') ||
              e.toString().contains('PARSING:'))) {
        rethrow;
      }
      throw Exception('PARSING:Failed to process parking zone data.');
    }
  }

  // ============================================================================
  // USER REPORT METHODS
  // ============================================================================

  /// Add a new user report for parking occupancy
  ///
  /// [report] - UserReport model containing report data
  ///
  /// Returns report ID from API response
  /// Throws Exception with user-friendly message on error
  Future<String> addUserReport(UserReport report) async {
    try {
      final response = await _apiService.post(
        '/api/reports',
        body: {
          'spotId': report.spotId,
          'reportedCount': report.reportedCount,
          'userLatitude': report.userLatitude,
          'userLongitude': report.userLongitude,
          'timestamp': report.timestamp.toIso8601String(),
        },
      );

      // Use robust parsing helper
      final data = _extractObjectFromResponse(response, 'addUserReport');
      if (data == null || data['id'] == null) {
        throw Exception(
            'PARSING:Invalid response from server. Please try again.');
      }

      return data['id'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('AUTH:Your session has expired. Please log in again.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('TIMEOUT:Request timed out. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'NETWORK:Unable to connect to server. Please check your network.');
      }
      throw Exception('API:Failed to submit report. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception: ') &&
          (e.toString().contains('AUTH:') ||
              e.toString().contains('NETWORK:') ||
              e.toString().contains('API:') ||
              e.toString().contains('TIMEOUT:') ||
              e.toString().contains('PARSING:'))) {
        rethrow;
      }
      throw Exception('PARSING:Failed to process report data.');
    }
  }

  /// Get recent reports for a specific parking spot
  ///
  /// [spotId] - Parking spot ID
  /// [hours] - Number of hours to look back (default: 24)
  ///
  /// Returns list of UserReport objects
  /// Throws Exception with user-friendly message on error
  Future<List<UserReport>> getRecentReports(
    String spotId, {
    int hours = 24,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/reports',
        queryParams: {
          'spotId': spotId,
          'hours': hours,
        },
      );

      // Use robust parsing helper
      final dataList = _extractListFromResponse(response, 'getRecentReports');

      return dataList
          .map((json) => UserReport.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('AUTH:Your session has expired. Please log in again.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('TIMEOUT:Request timed out. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'NETWORK:Unable to connect to server. Please check your network.');
      }
      throw Exception('API:Failed to fetch reports. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception: ') &&
          (e.toString().contains('AUTH:') ||
              e.toString().contains('NETWORK:') ||
              e.toString().contains('API:') ||
              e.toString().contains('TIMEOUT:') ||
              e.toString().contains('PARSING:'))) {
        rethrow;
      }
      throw Exception('PARSING:Failed to process report data.');
    }
  }

  // ============================================================================
  // IMAGE UPLOAD METHOD
  // ============================================================================

  /// Upload an image for a report
  ///
  /// [file] - Image file to upload
  /// [reportId] - Report ID to associate the image with
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns image URL from API response
  /// Throws Exception with user-friendly message on error
  Future<String> uploadImage(
    File file,
    String reportId, {
    Function(double)? onProgress,
  }) async {
    try {
      final response = await _apiService.uploadFile(
        '/api/reports/$reportId/images',
        file,
        onProgress: onProgress,
      );

      // Use robust parsing helper
      final data = _extractObjectFromResponse(response, 'uploadImage');
      if (data == null || data['imageUrl'] == null) {
        throw Exception(
            'PARSING:Invalid response from server. Please try again.');
      }

      return data['imageUrl'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('AUTH:Your session has expired. Please log in again.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('TIMEOUT:Upload timed out. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'NETWORK:Unable to connect to server. Please check your network.');
      }
      throw Exception('API:Failed to upload image. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception: ') &&
          (e.toString().contains('AUTH:') ||
              e.toString().contains('NETWORK:') ||
              e.toString().contains('API:') ||
              e.toString().contains('TIMEOUT:') ||
              e.toString().contains('PARSING:'))) {
        rethrow;
      }
      throw Exception('PARSING:Failed to process upload response.');
    }
  }
}
