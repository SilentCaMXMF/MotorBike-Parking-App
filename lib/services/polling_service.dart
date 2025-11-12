import 'dart:async';
import 'package:motorbike_parking_app/models/parking_zone.dart';
import 'package:motorbike_parking_app/services/sql_service.dart';

/// Service for polling parking zone data at regular intervals
/// Provides real-time updates without WebSocket connection
class PollingService {
  Timer? _timer;
  final SqlService _sqlService;
  final Duration _pollInterval;

  /// Creates a PollingService instance
  /// 
  /// [sqlService] - Optional SqlService instance for dependency injection
  /// [pollInterval] - Duration between polls (default: 30 seconds)
  PollingService({
    SqlService? sqlService,
    Duration pollInterval = const Duration(seconds: 30),
  })  : _sqlService = sqlService ?? SqlService(),
        _pollInterval = pollInterval;

  /// Starts polling for parking zone updates
  /// 
  /// [latitude] - User's current latitude
  /// [longitude] - User's current longitude
  /// [onUpdate] - Callback invoked with updated parking zones
  /// [onError] - Callback invoked when an error occurs
  /// [radius] - Search radius in kilometers (default: 5.0)
  /// [limit] - Maximum number of zones to fetch (default: 50)
  void startPolling({
    required double latitude,
    required double longitude,
    required Function(List<ParkingZone>) onUpdate,
    required Function(String) onError,
    double radius = 5.0,
    int limit = 50,
  }) {
    // Stop any existing polling to prevent multiple timers
    stopPolling();

    // Fetch data immediately on start
    _fetchParkingZones(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      limit: limit,
      onUpdate: onUpdate,
      onError: onError,
    );

    // Set up periodic polling
    _timer = Timer.periodic(_pollInterval, (timer) {
      _fetchParkingZones(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
        onUpdate: onUpdate,
        onError: onError,
      );
    });
  }

  /// Stops the polling timer and cleans up resources
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Checks if polling is currently active
  bool get isPolling => _timer != null && _timer!.isActive;

  /// Internal method to fetch parking zones
  Future<void> _fetchParkingZones({
    required double latitude,
    required double longitude,
    required double radius,
    required int limit,
    required Function(List<ParkingZone>) onUpdate,
    required Function(String) onError,
  }) async {
    try {
      final zones = await _sqlService.getParkingZones(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
      );
      onUpdate(zones);
    } catch (e) {
      onError(e.toString());
    }
  }
}
