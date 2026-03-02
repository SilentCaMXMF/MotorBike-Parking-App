import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorbike_parking_app/services/notification_service.dart';

@GenerateMocks([
  GeolocatorPlatform,
  NotificationService,
])
void main() {}
