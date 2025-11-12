import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:motorbike_parking_app/services/api_service.dart';
import 'package:motorbike_parking_app/services/location_service.dart';
import 'package:motorbike_parking_app/services/polling_service.dart';
import 'package:motorbike_parking_app/services/notification_service.dart';
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
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pollingService.stopPolling();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollingService.stopPolling();
    }
  }

  // Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      // Check initial connectivity status
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);

      // Listen for connectivity changes
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
      );
    } catch (e) {
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

    setState(() {
      _isOnline = isNowOnline;
    });

    // Connection restored - retry pending operations
    if (!wasOnline && isNowOnline) {
      _onConnectionRestored();
    }

    // Connection lost - show notification
    if (wasOnline && !isNowOnline) {
      _onConnectionLost();
    }
  }

  // Handle connection restored
  void _onConnectionRestored() {
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

    final operations = List<Function>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operations) {
      try {
        await operation();
      } catch (e) {
        // If operation fails, queue it again
        _queueOperation(operation);
      }
    }
  }

  void _startPolling() {
    // Don't start polling if offline
    if (!_isOnline) {
      return;
    }

    _pollingService.startPolling(
      latitude: _center.latitude,
      longitude: _center.longitude,
      onUpdate: (List<ParkingZone> zones) {
        setState(() {
          _parkingZones = zones;
          _isLoading = false;
          _error = null;
        });
        _updateMarkers(zones);
      },
      onError: (String error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      mapController.animateCamera(CameraUpdate.newLatLng(_center));
      _checkProximityNotifications(position);
      // Start polling after getting location
      _startPolling();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: ${e.toString()}')),
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
      body: Stack(
        children: [
          _buildBody(),
          // Offline indicator banner
          if (!_isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          const Center(
            child: CircularProgressIndicator(),
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
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading parking zones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _startPolling();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
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
