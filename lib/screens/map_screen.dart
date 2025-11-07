import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/models.dart';
import '../widgets/reporting_dialog.dart';
import 'auth_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  LatLng _center = const LatLng(38.7223, -9.1393); // Lisbon coordinates
  Set<Marker> _markers = {};
  List<ParkingZone> _currentZones = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      mapController.animateCamera(CameraUpdate.newLatLng(_center));
      _checkProximityNotifications(position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: ${e.toString()}')),
      );
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
              await AuthService().signOut();
              // Navigation handled by AuthWrapper
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ParkingZone>>(
        stream: _firestoreService.getParkingZones(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _updateMarkers(snapshot.data!);
            // Check proximity on data update
            _getCurrentLocation();
          }
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
        },
      ),
    );
  }
}