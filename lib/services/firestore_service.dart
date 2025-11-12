// ============================================================================
// FIRESTORE SERVICE - COMMENTED OUT FOR API MIGRATION
// ============================================================================
// This file is preserved for potential scaling back to Firebase if the local
// Raspberry Pi backend reaches capacity limits.
//
// The app has been migrated to use a custom REST API backend with MariaDB
// instead of Firebase Firestore. This service is kept in the project to enable
// quick rollback if needed.
//
// ROLLBACK INSTRUCTIONS:
// To re-enable Firebase and use this service:
//
// 1. Uncomment Firebase packages in pubspec.yaml:
//    - firebase_core: ^2.17.0
//    - firebase_auth: ^4.10.0
//    - cloud_firestore: ^4.9.3
//    - firebase_storage: ^11.2.8
//
// 2. Run: flutter pub get
//
// 3. Uncomment the imports and class implementation below
//
// 4. Uncomment Firebase initialization in lib/main.dart:
//    - await FirestoreService().initializeFirebase();
//
// 5. Update service injection to use FirestoreService instead of ApiService
//
// 6. Uncomment Firebase configuration:
//    - lib/firebase_options.dart
//    - android/build.gradle (Firebase plugin classpath)
//    - android/app/build.gradle (google-services plugin)
//    - ios/Podfile (run pod install after uncommenting)
//
// 7. Clean and rebuild:
//    - flutter clean
//    - flutter pub get
//    - flutter build apk (Android) or flutter build ios (iOS)
//
// CURRENT STATUS: Inactive (commented out)
// MIGRATION DATE: November 2025
// REASON: Cost reduction and data ownership via local backend
// ============================================================================

/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/models.dart';
import 'availability_engine.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  // Get all parking zones
  Stream<List<ParkingZone>> getParkingZones() {
    return _firestore.collection('parking_zones').snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ParkingZone.fromJson(data);
        }).toList();
      } catch (e) {
        print('Error parsing parking zones: $e');
        return []; // Return empty list on parse error
      }
    });
  }

  // Get a specific parking zone
  Future<ParkingZone?> getParkingZone(String id) async {
    try {
      final doc = await _firestore.collection('parking_zones').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ParkingZone.fromJson(data);
      }
      return null;
    } catch (e) {
      // Log error but return null for graceful failure
      print('Error fetching parking zone $id: $e');
      return null;
    }
  }

  // Add or update a parking zone
  Future<void> setParkingZone(ParkingZone zone) async {
    try {
      await _firestore.collection('parking_zones').doc(zone.id).set(zone.toJson());
    } catch (e) {
      throw Exception('Failed to save parking zone: $e');
    }
  }

  // Add a user report
  Future<DocumentReference> addUserReport(UserReport report) async {
    try {
      final docRef = await _firestore.collection('user_reports').add(report.toJson());

      // Update zone with new calculations
      final recentReports = await getRecentReports(report.spotId);
      final zone = await getParkingZone(report.spotId);
      if (zone != null) {
        final updatedZone = AvailabilityEngine.updateZoneWithReports(zone, recentReports);
        await setParkingZone(updatedZone);
      }

      return docRef;
    } catch (e) {
      throw Exception('Failed to add user report: $e');
    }
  }

  // Update a user report
  Future<void> updateUserReport(String id, UserReport report) async {
    try {
      await _firestore.collection('user_reports').doc(id).update(report.toJson());
    } catch (e) {
      throw Exception('Failed to update user report: $e');
    }
  }

  // Get recent reports for a zone
  Future<List<UserReport>> getRecentReports(String spotId, {int hours = 24}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(hours: hours));
      final query = await _firestore
          .collection('user_reports')
          .where('spotId', isEqualTo: spotId)
          .where('timestamp', isGreaterThan: cutoff)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) => UserReport.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching recent reports for $spotId: $e');
      return []; // Return empty list on error
    }
  }

  // Update zone occupancy based on reports
  Future<void> updateZoneOccupancy(String zoneId, int newOccupancy) async {
    try {
      await _firestore.collection('parking_zones').doc(zoneId).update({
        'currentOccupancy': newOccupancy,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update zone occupancy: $e');
    }
  }
}
*/

// ============================================================================
// END FIRESTORE SERVICE
// ============================================================================
