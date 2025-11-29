import 'package:flutter_test/flutter_test.dart';
import 'package:motorbike_parking_app/models/models.dart';
import 'package:motorbike_parking_app/services/availability_engine.dart';

void main() {
  group('AvailabilityEngine', () {
    group('calculateCurrentOccupancy', () {
      test('returns 0 for empty reports', () {
        final reports = <UserReport>[];
        final result = AvailabilityEngine.calculateCurrentOccupancy(reports);
        expect(result, 0);
      });

      test('returns single report count for one report', () {
        final reports = [
          UserReport(
            spotId: 'zone1',
            userId: 'user1',
            reportedCount: 5,
            timestamp: DateTime.now(),
          ),
        ];
        final result = AvailabilityEngine.calculateCurrentOccupancy(reports);
        expect(result, 5);
      });

      test('weights recent reports higher', () {
        final now = DateTime.now();
        final reports = [
          UserReport(
            spotId: 'zone1',
            userId: 'user1',
            reportedCount: 10,
            timestamp: now.subtract(const Duration(minutes: 10)), // Recent
          ),
          UserReport(
            spotId: 'zone1',
            userId: 'user2',
            reportedCount: 5,
            timestamp: now.subtract(const Duration(minutes: 70)), // Older
          ),
        ];
        final result = AvailabilityEngine.calculateCurrentOccupancy(reports);
        // Should be closer to 10 than to 7.5 (average)
        expect(result, greaterThan(7));
      });
    });

    group('calculateConfidenceScore', () {
      test('returns 0.0 for empty reports', () {
        final reports = <UserReport>[];
        final result = AvailabilityEngine.calculateConfidenceScore(reports, 10);
        expect(result, 0.0);
      });

      test('returns high confidence for recent consistent reports', () {
        final now = DateTime.now();
        final reports = [
          UserReport(
            spotId: 'zone1',
            userId: 'user1',
            reportedCount: 5,
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          UserReport(
            spotId: 'zone1',
            userId: 'user2',
            reportedCount: 5,
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
          UserReport(
            spotId: 'zone1',
            userId: 'user3',
            reportedCount: 5,
            timestamp: now.subtract(const Duration(minutes: 15)),
          ),
        ];
        final result = AvailabilityEngine.calculateConfidenceScore(reports, 10);
        expect(result, greaterThan(0.7));
      });

      test('returns low confidence for inconsistent reports', () {
        final now = DateTime.now();
        final reports = [
          UserReport(
            spotId: 'zone1',
            userId: 'user1',
            reportedCount: 1,
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          UserReport(
            spotId: 'zone1',
            userId: 'user2',
            reportedCount: 10,
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
        ];
        final result = AvailabilityEngine.calculateConfidenceScore(reports, 10);
        expect(result, lessThan(0.5));
      });
    });

    group('updateZoneWithReports', () {
      test('updates zone occupancy and confidence', () {
        final zone = ParkingZone(
          id: 'zone1',
          latitude: 38.7223,
          longitude: -9.1393,
          totalCapacity: 10,
          currentOccupancy: 0,
          confidenceScore: 0.0,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
          userReports: [],
        );

        final reports = [
          UserReport(
            spotId: 'zone1',
            userId: 'user1',
            reportedCount: 7,
            timestamp: DateTime.now(),
          ),
        ];

        final updatedZone =
            AvailabilityEngine.updateZoneWithReports(zone, reports);

        expect(updatedZone.currentOccupancy, 7);
        expect(updatedZone.confidenceScore, greaterThan(0.0));
        expect(updatedZone.userReports.length, 1);
        expect(updatedZone.lastUpdated.isAfter(zone.lastUpdated), true);
      });

      test('clamps occupancy to capacity', () {
        final zone = ParkingZone(
          id: 'zone1',
          latitude: 38.7223,
          longitude: -9.1393,
          totalCapacity: 10,
          currentOccupancy: 0,
          confidenceScore: 0.0,
          lastUpdated: DateTime.now(),
          userReports: [],
        );

        final reports = [
          UserReport(
            spotId: 'zone1',
            userId: 'user1',
            reportedCount: 15, // Over capacity
            timestamp: DateTime.now(),
          ),
        ];

        final updatedZone =
            AvailabilityEngine.updateZoneWithReports(zone, reports);

        expect(updatedZone.currentOccupancy, 10); // Clamped to capacity
      });
    });
  });
}
