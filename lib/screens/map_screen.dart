import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/polling_service.dart';
import '../services/notification_service.dart';
import '../models/models.dart';
import '../widgets/reporting_dialog.dart';

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

  LatLng _center = const LatLng(38.7223, -9.1393); // Lisbon coordinates
  Set<Marker> _markers = {};
  List<ParkingZone> _currentZones = [];

  // State variables for polling implementation
  List<ParkingZone> _parkingZones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pollingService.stopPolling();
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

  void _startPolling() {
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
      body: _buildBody(),
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
