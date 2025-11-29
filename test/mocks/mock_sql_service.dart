import 'dart:io';
import '../../lib/services/sql_service.dart';
import '../../lib/models/parking_zone.dart';
import '../../lib/models/user_report.dart';

/// Mock SQL Service for testing
/// Provides configurable responses for all SQL service methods
class MockSqlService implements SqlService {
  String? _addUserReportResponse;
  Exception? _addUserReportException;
  String? _uploadImageResponse;
  Exception? _uploadImageException;
  List<ParkingZone>? _getParkingZonesResponse;
  Exception? _getParkingZonesException;

  // ============================================================================
  // USER REPORT MOCK RESPONSES
  // ============================================================================

  /// Setup successful addUserReport response
  void setupAddUserReportSuccess({String reportId = 'report-123'}) {
    _addUserReportResponse = reportId;
    _addUserReportException = null;
  }

  /// Setup addUserReport failure
  void setupAddUserReportFailure(Exception exception) {
    _addUserReportException = exception;
    _addUserReportResponse = null;
  }

  @override
  Future<String> addUserReport(UserReport report) async {
    if (_addUserReportException != null) {
      throw _addUserReportException!;
    }
    return _addUserReportResponse!;
  }

  // ============================================================================
  // IMAGE UPLOAD MOCK RESPONSES
  // ============================================================================

  /// Setup successful uploadImage response
  void setupUploadImageSuccess(
      {String imageUrl = 'https://example.com/image.jpg'}) {
    _uploadImageResponse = imageUrl;
    _uploadImageException = null;
  }

  /// Setup uploadImage failure
  void setupUploadImageFailure(Exception exception) {
    _uploadImageException = exception;
    _uploadImageResponse = null;
  }

  @override
  Future<String> uploadImage(
    File file,
    String reportId, {
    Function(double)? onProgress,
  }) async {
    // Simulate progress updates
    if (onProgress != null) {
      onProgress(0.5);
      await Future.delayed(const Duration(milliseconds: 10));
      onProgress(1.0);
    }

    if (_uploadImageException != null) {
      throw _uploadImageException!;
    }
    return _uploadImageResponse!;
  }

  // ============================================================================
  // PARKING ZONE MOCK RESPONSES
  // ============================================================================

  /// Setup successful getParkingZones response
  void setupGetParkingZonesSuccess(List<ParkingZone> zones) {
    _getParkingZonesResponse = zones;
    _getParkingZonesException = null;
  }

  /// Setup getParkingZones failure
  void setupGetParkingZonesFailure(Exception exception) {
    _getParkingZonesException = exception;
    _getParkingZonesResponse = null;
  }

  @override
  Future<List<ParkingZone>> getParkingZones({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int limit = 50,
  }) async {
    if (_getParkingZonesException != null) {
      throw _getParkingZonesException!;
    }
    return _getParkingZonesResponse!;
  }

  // ============================================================================
  // ADDITIONAL METHODS
  // ============================================================================

  @override
  Future<ParkingZone?> getParkingZone(String id) async {
    // Not used in ReportingDialog tests
    throw UnimplementedError();
  }

  @override
  Future<List<UserReport>> getRecentReports(
    String spotId, {
    int hours = 24,
  }) async {
    // Not used in ReportingDialog tests
    throw UnimplementedError();
  }
}
