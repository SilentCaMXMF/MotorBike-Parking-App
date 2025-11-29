import 'dart:async';
import 'package:motorbike_parking_app/models/parking_zone.dart';
import 'package:motorbike_parking_app/services/sql_service.dart';
import 'package:motorbike_parking_app/services/logger_service.dart';

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
    // Log polling start with all parameters
    LoggerService.debug(
      'startPolling() called with latitude=$latitude, longitude=$longitude, radius=$radius, limit=$limit, interval=${_pollInterval.inSeconds}s',
      component: 'PollingService',
    );

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

    // Log polling state after starting
    _logPollingState();
  }

  /// Stops the polling timer and cleans up resources
  void stopPolling() {
    LoggerService.debug(
      'stopPolling() called',
      component: 'PollingService',
    );
    _timer?.cancel();
    _timer = null;
    _logPollingState();
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
    LoggerService.debug(
      '_fetchParkingZones() called before SqlService.getParkingZones()',
      component: 'PollingService',
    );

    try {
      final zones = await _sqlService.getParkingZones(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
      );

      LoggerService.debug(
        'onUpdate callback invoked with ${zones.length} parking zones',
        component: 'PollingService',
      );
      onUpdate(zones);
    } catch (e) {
      LoggerService.debug(
        'onError callback invoked with error: ${e.toString()}',
        component: 'PollingService',
      );
      onError(e.toString());
    }
  }

  /// Logs the current polling state (active/inactive)
  void _logPollingState() {
    final state = isPolling ? 'active' : 'inactive';
    LoggerService.debug(
      'Polling state: $state',
      component: 'PollingService',
    );
  }
}
