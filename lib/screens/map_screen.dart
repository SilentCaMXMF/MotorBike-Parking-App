import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:motorbike_parking_app/services/api_service.dart';
import 'package:motorbike_parking_app/services/location_service.dart';
import 'package:motorbike_parking_app/services/polling_service.dart';
import 'package:motorbike_parking_app/services/notification_service.dart';
import 'package:motorbike_parking_app/services/logger_service.dart';
import 'package:motorbike_parking_app/models/parking_zone.dart';
import 'package:motorbike_parking_app/widgets/reporting_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  late GoogleMapController mapController;
  final LocationService _locationService = LocationService();
  final PollingService _pollingService = PollingService();
  final NotificationService _notificationService = NotificationService();
  final Connectivity _connectivity = Connectivity();

  LatLng _center = const LatLng(38.7223, -9.1393); // Lisbon coordinates
  Set<Marker> _markers = {};
  List<ParkingZone> _currentZones = [];

  // State variables for polling implementation
  List<ParkingZone> _parkingZones = [];
  bool _isLoading = true;
  String? _error;

  // Connection state monitoring
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final List<Function> _pendingOperations = [];

  @override
  void initState() {
    super.initState();
    LoggerService.debug('MapScreen initialized', component: 'MapScreen');
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    LoggerService.debug('MapScreen disposing', component: 'MapScreen');
    _pollingService.stopPolling();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LoggerService.debug(
      'App lifecycle state changed to: $state',
      component: 'MapScreen',
    );
    if (state == AppLifecycleState.resumed) {
      LoggerService.info('App resumed, starting polling',
          component: 'MapScreen');
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      LoggerService.info('App paused, stopping polling',
          component: 'MapScreen');
      _pollingService.stopPolling();
    }
  }

  // Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      LoggerService.debug('Initializing connectivity monitoring',
          component: 'MapScreen');
      // Check initial connectivity status
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
      );
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to initialize connectivity monitoring',
        error: e,
        stackTrace: stackTrace,
        component: 'MapScreen',
      );
      // If connectivity check fails, assume online
      setState(() {
        _isOnline = true;
      });
    }
  }

  // Update connection status and handle state changes
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool wasOnline = _isOnline;
    final bool isNowOnline = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    LoggerService.info(
      'Connectivity status: ${isNowOnline ? "online" : "offline"} (was: ${wasOnline ? "online" : "offline"})',
      component: 'MapScreen',
    );

    setState(() {
      _isOnline = isNowOnline;
    });

    // Connection restored - retry pending operations
    if (!wasOnline && isNowOnline) {
      LoggerService.info(
        'Connectivity state change: offline → online',
        component: 'MapScreen',
      );
      _onConnectionRestored();
    }

    // Connection lost - show notification
    if (wasOnline && !isNowOnline) {
      LoggerService.warning(
        'Connectivity state change: online → offline',
        component: 'MapScreen',
      );
      _onConnectionLost();
    }
  }

  // Handle connection restored
  void _onConnectionRestored() {
    LoggerService.info('Connection restored', component: 'MapScreen');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('Connection restored'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Retry pending operations
    _retryPendingOperations();

    // Restart polling if not already running
    _startPolling();
  }

  // Handle connection lost
  void _onConnectionLost() {
    LoggerService.warning('Connection lost', component: 'MapScreen');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Connection lost - working offline'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Stop polling when offline
    _pollingService.stopPolling();
  }

  // Queue an operation for retry when connection is restored
  void _queueOperation(Function operation) {
    _pendingOperations.add(operation);
  }

  // Retry all pending operations
  Future<void> _retryPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    LoggerService.info(
      'Retrying ${_pendingOperations.length} pending operations',
      component: 'MapScreen',
    );

    final operations = List<Function>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operations) {
      try {
        await operation();
      } catch (e, stackTrace) {
        LoggerService.error(
          'Failed to retry pending operation',
          error: e,
          stackTrace: stackTrace,
          component: 'MapScreen',
        );
        // If operation fails, queue it again
        _queueOperation(operation);
      }
    }
  }

  /// Check if authentication token exists before starting polling
  Future<bool> _checkAuthentication() async {
    final token = await ApiService().getToken();

    if (token == null || token.isEmpty) {
      LoggerService.warning(
        'Cannot start polling: No authentication token',
        component: 'MapScreen',
      );
      setState(() {
        _error = 'AUTH:Authentication required. Please log in again.';
        _isLoading = false;
      });
      return false;
    }

    LoggerService.debug(
      'Authentication verified, token present',
      component: 'MapScreen',
    );
    return true;
  }

  /// Handle authentication errors by prompting user to log in again
  void _handleAuthenticationError(String error) {
    LoggerService.warning(
      'Authentication error detected, prompting re-login',
      component: 'MapScreen',
    );

    setState(() {
      _error = error;
      _isLoading = false;
    });

    // Stop polling to prevent further failed requests
    _pollingService.stopPolling();

    // Show dialog prompting user to log in again
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Session Expired'),
            ],
          ),
          content: Text(
            error.replaceFirst('AUTH:', '').replaceFirst('Exception: ', ''),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Sign out and let AuthWrapper handle navigation
                await ApiService().signOut();
              },
              child: const Text('Log In Again'),
            ),
          ],
        ),
      );
    }
  }

  void _startPolling() async {
    LoggerService.debug(
      '_startPolling() called with location coordinates: lat=${_center.latitude}, lng=${_center.longitude}',
      component: 'MapScreen',
    );

    // Don't start polling if offline
    if (!_isOnline) {
      LoggerService.warning(
        'Polling stopped due to offline status',
        component: 'MapScreen',
      );
      return;
    }

    // Check authentication before starting polling
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      return;
    }

    LoggerService.info(
      'Starting polling at location: ${_center.latitude}, ${_center.longitude}',
      component: 'MapScreen',
    );

    _pollingService.startPolling(
      latitude: _center.latitude,
      longitude: _center.longitude,
      onUpdate: (List<ParkingZone> zones) {
        LoggerService.debug(
          'Zones received in onUpdate callback: ${zones.length} parking zones',
          component: 'MapScreen',
        );
        setState(() {
          _parkingZones = zones;
          _isLoading = false;
          _error = null;
        });
        _updateMarkers(zones);
      },
      onError: (String error) {
        LoggerService.error(
          'Error occurred in onError callback: $error',
          component: 'MapScreen',
        );

        // Handle authentication errors specially
        if (error.contains('AUTH:')) {
          _handleAuthenticationError(error);
        } else {
          setState(() {
            _error = error;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      LoggerService.debug('Getting current location', component: 'MapScreen');
      Position position = await _locationService.getCurrentLocation();
      LoggerService.info(
        'Location obtained: ${position.latitude}, ${position.longitude}',
        component: 'MapScreen',
      );
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      mapController.animateCamera(CameraUpdate.newLatLng(_center));
      _checkProximityNotifications(position);
      // Start polling after getting location
      _startPolling();
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to get current location',
        error: e,
        stackTrace: stackTrace,
        component: 'MapScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to get your location. Using default location.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // Start polling with default location even if location fetch fails
      _startPolling();
    }
  }

  void _checkProximityNotifications(Position position) {
    _notificationService.checkProximityAndNotify(position, _currentZones);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Color _getMarkerColor(ParkingZone zone) {
    double ratio = zone.availableSlots / zone.totalCapacity;
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.25) return Colors.yellow;
    return Colors.red;
  }

  BitmapDescriptor _getMarkerIcon(Color color) {
    // For simplicity, use default marker. In real app, customize icons.
    return BitmapDescriptor.defaultMarkerWithHue(
      color == Colors.green
          ? BitmapDescriptor.hueGreen
          : color == Colors.yellow
              ? BitmapDescriptor.hueYellow
              : BitmapDescriptor.hueRed,
    );
  }

  void _updateMarkers(List<ParkingZone> zones) {
    LoggerService.debug(
      '_updateMarkers() called with ${zones.length} zones',
      component: 'MapScreen',
    );
    _currentZones = zones;
    Set<Marker> markers = {};
    for (final ParkingZone zone in zones) {
      markers.add(
        Marker(
          markerId: MarkerId(zone.id),
          position: LatLng(zone.latitude, zone.longitude),
          icon: _getMarkerIcon(_getMarkerColor(zone)),
          infoWindow: InfoWindow(
            title: 'Parking Zone',
            snippet:
                '${zone.availableSlots}/${zone.totalCapacity} available\nConfidence: ${(zone.confidenceScore * 100).toInt()}%',
          ),
          onTap: () => _showZoneDetails(zone),
        ),
      );
    }
    LoggerService.debug('Updated ${markers.length} markers on map',
        component: 'MapScreen');
    setState(() {
      _markers = markers;
    });
  }

  void _showZoneDetails(ParkingZone zone) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parking Zone ${zone.id}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Capacity: ${zone.totalCapacity}'),
            Text('Available: ${zone.availableSlots}'),
            Text('Confidence: ${(zone.confidenceScore * 100).toInt()}%'),
            Text('Last Updated: ${zone.lastUpdated}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _reportParking(zone),
              child: const Text('Report Current Count'),
            ),
          ],
        ),
      ),
    );
  }

  void _reportParking(ParkingZone zone) {
    showDialog(
      context: context,
      builder: (_) => ReportingDialog(zone: zone),
    );
  }

  Future<void> _refreshParkingZones() async {
    LoggerService.info('Refreshing parking zones', component: 'MapScreen');
    // Stop current polling
    _pollingService.stopPolling();

    // Reset state
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Restart polling
    _startPolling();

    // Wait a bit for data to load
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Get appropriate icon based on error type
  Widget _getErrorIcon(String error) {
    IconData iconData;
    Color iconColor;

    if (error.contains('AUTH:')) {
      iconData = Icons.lock_outline;
      iconColor = Colors.orange;
    } else if (error.contains('NETWORK:')) {
      iconData = Icons.wifi_off;
      iconColor = Colors.red;
    } else if (error.contains('TIMEOUT:')) {
      iconData = Icons.access_time;
      iconColor = Colors.orange;
    } else if (error.contains('API:')) {
      iconData = Icons.cloud_off;
      iconColor = Colors.red;
    } else if (error.contains('PARSING:')) {
      iconData = Icons.error_outline;
      iconColor = Colors.red;
    } else {
      iconData = Icons.error_outline;
      iconColor = Colors.red;
    }

    return Icon(iconData, color: iconColor, size: 48);
  }

  /// Get appropriate title based on error type
  String _getErrorTitle(String error) {
    if (error.contains('AUTH:')) {
      return 'Authentication Required';
    } else if (error.contains('NETWORK:')) {
      return 'Connection Error';
    } else if (error.contains('TIMEOUT:')) {
      return 'Request Timed Out';
    } else if (error.contains('API:')) {
      return 'Service Error';
    } else if (error.contains('PARSING:')) {
      return 'Data Error';
    } else {
      return 'Error Loading Parking Zones';
    }
  }

  /// Get clean error message without prefix
  String _getErrorMessage(String error) {
    String message = error;

    // Remove error type prefix
    message = message.replaceFirst('AUTH:', '');
    message = message.replaceFirst('NETWORK:', '');
    message = message.replaceFirst('TIMEOUT:', '');
    message = message.replaceFirst('API:', '');
    message = message.replaceFirst('PARSING:', '');
    message = message.replaceFirst('Exception: ', '');

    return message.trim();
  }

  /// Build appropriate action buttons based on error type
  Widget _buildErrorActions(String error) {
    if (error.contains('AUTH:')) {
      // For auth errors, show login button
      return ElevatedButton.icon(
        onPressed: () async {
          await ApiService().signOut();
          // AuthWrapper will handle navigation to login
        },
        icon: const Icon(Icons.login),
        label: const Text('Log In Again'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      // For other errors, show retry button
      return ElevatedButton.icon(
        onPressed: () async {
          LoggerService.info('Retry button pressed', component: 'MapScreen');
          setState(() {
            _isLoading = true;
            _error = null;
          });

          // For network errors, check connectivity first
          if (error.contains('NETWORK:') || error.contains('TIMEOUT:')) {
            final List<ConnectivityResult> results =
                await _connectivity.checkConnectivity();
            final bool isConnected = results.isNotEmpty &&
                results.any((result) => result != ConnectivityResult.none);

            if (!isConnected) {
              setState(() {
                _isLoading = false;
                _error =
                    'NETWORK:No internet connection. Please check your network and try again.';
              });
              return;
            }
          }

          _startPolling();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorbike Parking Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService().signOut();
              // Navigation handled by AuthWrapper
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshParkingZones,
        child: Stack(
          children: [
            _buildBody(),
            // Offline indicator banner
            if (!_isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orange,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Offline - Limited functionality',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Display loading indicator when loading
    if (_isLoading) {
      return Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading parking zones...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Display error message and retry button when error occurs
    if (_error != null) {
      return Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getErrorIcon(_error!),
                  const SizedBox(height: 16),
                  Text(
                    _getErrorTitle(_error!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getErrorMessage(_error!),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildErrorActions(_error!),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Display map with markers when data is loaded successfully
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
