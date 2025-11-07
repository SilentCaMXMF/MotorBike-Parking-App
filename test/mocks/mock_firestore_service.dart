import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import '../../lib/services/firestore_service.dart';
import '../../lib/models/models.dart';

// Mock FirebaseFirestore
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// Mock DocumentReference
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {
  @override
  String get id => 'test-doc-id';
}

// Mock DocumentSnapshot
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  MockDocumentSnapshot(this._data, this._exists);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => 'test-doc-id';
}

// Mock QuerySnapshot
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {
  final List<MockDocumentSnapshot> _docs;

  MockQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      _docs.where((doc) => doc.exists).cast<QueryDocumentSnapshot<Map<String, dynamic>>>().toList();
}

// Mock CollectionReference
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

// Mock FirestoreService
class MockFirestoreService extends Mock implements FirestoreService {
  final MockFirebaseFirestore _mockFirestore = MockFirebaseFirestore();
  final MockCollectionReference _mockCollection = MockCollectionReference();

  // Setup defaults
  void setupDefaults() {
    when(_mockFirestore.collection(any)).thenReturn(_mockCollection);
  }

  // Setup getParkingZone success
  void setupGetParkingZoneSuccess(ParkingZone zone) {
    final mockDoc = MockDocumentSnapshot(zone.toJson(), true);
    when(_mockCollection.doc(zone.id).get())
        .thenAnswer((_) async => mockDoc);
  }

  // Setup getParkingZone not found
  void setupGetParkingZoneNotFound(String zoneId) {
    final mockDoc = MockDocumentSnapshot(null, false);
    when(_mockCollection.doc(zoneId).get())
        .thenAnswer((_) async => mockDoc);
  }

  // Setup getRecentReports success
  void setupGetRecentReportsSuccess(List<UserReport> reports) {
    final docs = reports.map((report) => MockDocumentSnapshot(report.toJson(), true)).toList();
    final mockQuerySnapshot = MockQuerySnapshot(docs);
    when(_mockCollection.where('spotId', isEqualTo: anyNamed('isEqualTo')))
        .thenReturn(_mockCollection);
    when(_mockCollection.where('timestamp', isGreaterThan: anyNamed('isGreaterThan')))
        .thenReturn(_mockCollection);
    when(_mockCollection.orderBy('timestamp', descending: true))
        .thenReturn(_mockCollection);
    when(_mockCollection.get())
        .thenAnswer((_) async => mockQuerySnapshot);
  }

  // Setup addUserReport success
  void setupAddUserReportSuccess() {
    final mockDocRef = MockDocumentReference();
    when(_mockCollection.add(any))
        .thenAnswer((_) async => mockDocRef);
  }

  // Setup setParkingZone success
  void setupSetParkingZoneSuccess() {
    when(_mockCollection.doc(any).set(any))
        .thenAnswer((_) async {});
  }

  // Setup update success
  void setupUpdateOccupancySuccess() {
    when(_mockCollection.doc(any).update(any))
        .thenAnswer((_) async {});
  }
}