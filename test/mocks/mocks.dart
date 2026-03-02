import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import '../../lib/services/location_service.dart';
import '../../lib/services/notification_service.dart';

@GenerateMocks([
  GeolocatorPlatform,
  NotificationService,
])
void main() {}
