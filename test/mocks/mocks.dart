import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/services/firestore_service.dart';
import '../../lib/services/location_service.dart';
import '../../lib/services/notification_service.dart';

// Generate mocks for external dependencies
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  GeolocatorPlatform,
  User,
  UserCredential,
  ImagePicker,
  XFile,
])

// Generate mocks for our services
@GenerateMocks([
  AuthService,
  FirestoreService,
  LocationService,
  NotificationService,
])
void main() {}
