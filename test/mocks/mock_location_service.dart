import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:motorbike_parking_app/services/location_service.dart';

// Mock Position
class MockPosition extends Mock implements Position {
  @override
  double get latitude => 38.7223;

  @override
  double get longitude => -9.1393;

  @override
  double get accuracy => 10.0;

  @override
  double get altitude => 0.0;

  @override
  double get heading => 0.0;

  @override
  double get speed => 0.0;

  @override
  double get speedAccuracy => 0.0;

  @override
  DateTime get timestamp => DateTime.now();

  @override
  bool get isMocked => true;
}

// Mock LocationService
class MockLocationService extends Mock implements LocationService {
  // Setup getCurrentLocation success
  void setupGetCurrentLocationSuccess() {
    when(this.getCurrentLocation())
        .thenAnswer((_) async => MockPosition());
  }

  // Setup getCurrentLocation failure
  void setupGetCurrentLocationFailure(Exception exception) {
    when(this.getCurrentLocation())
        .thenThrow(exception);
  }

  // Setup location services disabled
  void setupLocationServicesDisabled() {
    when(this.getCurrentLocation())
        .thenThrow(Exception('Location services are disabled. Please enable location services to continue.'));
  }

  // Setup permission denied
  void setupPermissionDenied() {
    when(this.getCurrentLocation())
        .thenThrow(Exception('Location permissions are denied. Please grant location permission to use this feature.'));
  }

  // Setup timeout
  void setupTimeout() {
    when(this.getCurrentLocation())
        .thenThrow(Exception('Location request timed out. Please try again.'));
  }
}