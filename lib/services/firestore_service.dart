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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Get all parking zones
  Stream<List<ParkingZone>> getParkingZones() {
    return _firestore.collection('parking_zones').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ParkingZone.fromJson(data);
      }).toList();
    });
  }

  // Get a specific parking zone
  Future<ParkingZone?> getParkingZone(String id) async {
    final doc = await _firestore.collection('parking_zones').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return ParkingZone.fromJson(data);
    }
    return null;
  }

  // Add or update a parking zone
  Future<void> setParkingZone(ParkingZone zone) async {
    await _firestore.collection('parking_zones').doc(zone.id).set(zone.toJson());
  }

  // Add a user report
  Future<DocumentReference> addUserReport(UserReport report) async {
    final docRef = await _firestore.collection('user_reports').add(report.toJson());

    // Update zone with new calculations
    final recentReports = await getRecentReports(report.spotId);
    final zone = await getParkingZone(report.spotId);
    if (zone != null) {
      final updatedZone = AvailabilityEngine.updateZoneWithReports(zone, recentReports);
      await setParkingZone(updatedZone);
    }

    return docRef;
  }

  // Get recent reports for a zone
  Future<List<UserReport>> getRecentReports(String spotId, {int hours = 24}) async {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final query = await _firestore
        .collection('user_reports')
        .where('spotId', isEqualTo: spotId)
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: true)
        .get();

    return query.docs.map((doc) => UserReport.fromJson(doc.data())).toList();
  }

  // Update zone occupancy based on reports
  Future<void> updateZoneOccupancy(String zoneId, int newOccupancy) async {
    await _firestore.collection('parking_zones').doc(zoneId).update({
      'currentOccupancy': newOccupancy,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }
}