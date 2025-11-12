import 'dart:io';
import 'package:dio/dio.dart';
import '../models/parking_zone.dart';
import '../models/user_report.dart';
import 'api_service.dart';

/// SQL Service class that replaces FirestoreService with API-based implementations
/// Maintains the same method signatures for minimal UI component changes
class SqlService {
  final ApiService _apiService;

  // Singleton pattern implementation
  static final SqlService _instance = SqlService._internal();

  factory SqlService() => _instance;

  SqlService._internal() : _apiService = ApiService();

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
    try {
      final response = await _apiService.get(
        '/api/parking/nearby',
        queryParams: {
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
          'limit': limit,
        },
      );

      // Parse response data
      final data = response.data['data'];
      if (data is! List) {
        throw Exception(
            'Invalid response format: expected list of parking zones');
      }

      return data
          .map((json) => ParkingZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch parking zones: ${e.error}');
    } catch (e) {
      throw Exception('Failed to fetch parking zones: $e');
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

      final data = response.data['data'];
      if (data == null) {
        return null;
      }

      return ParkingZone.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch parking zone: ${e.error}');
    } catch (e) {
      throw Exception('Failed to fetch parking zone: $e');
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

      final data = response.data['data'];
      if (data == null || data['id'] == null) {
        throw Exception('Invalid response: missing report ID');
      }

      return data['id'] as String;
    } on DioException catch (e) {
      throw Exception('Failed to submit report: ${e.error}');
    } catch (e) {
      throw Exception('Failed to submit report: $e');
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

      final data = response.data['data'];
      if (data is! List) {
        throw Exception('Invalid response format: expected list of reports');
      }

      return data
          .map((json) => UserReport.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch reports: ${e.error}');
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
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

      final data = response.data['data'];
      if (data == null || data['imageUrl'] == null) {
        throw Exception('Invalid response: missing image URL');
      }

      return data['imageUrl'] as String;
    } on DioException catch (e) {
      throw Exception('Failed to upload image: ${e.error}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
