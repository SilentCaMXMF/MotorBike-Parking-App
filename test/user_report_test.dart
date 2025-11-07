import 'package:flutter_test/flutter_test.dart';
import 'package:motorbike_parking_app/models/user_report.dart';

void main() {
  group('UserReport', () {
    test('fromJson with imageUrls deserializes correctly', () {
      final json = {
        'spotId': 'zone1',
        'userId': 'user1',
        'reportedCount': 5,
        'timestamp': '2023-01-01T12:00:00.000Z',
        'userLatitude': 38.7223,
        'userLongitude': -9.1393,
        'imageUrls': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
      };

      final report = UserReport.fromJson(json);

      expect(report.spotId, 'zone1');
      expect(report.userId, 'user1');
      expect(report.reportedCount, 5);
      expect(report.imageUrls, ['https://example.com/image1.jpg', 'https://example.com/image2.jpg']);
      expect(report.userLatitude, 38.7223);
      expect(report.userLongitude, -9.1393);
    });

    test('fromJson without imageUrls defaults to empty list', () {
      final json = {
        'spotId': 'zone1',
        'userId': 'user1',
        'reportedCount': 5,
        'timestamp': '2023-01-01T12:00:00.000Z',
      };

      final report = UserReport.fromJson(json);

      expect(report.imageUrls, isEmpty);
    });

    test('fromJson with invalid imageUrls defaults to empty list', () {
      final json = {
        'spotId': 'zone1',
        'userId': 'user1',
        'reportedCount': 5,
        'timestamp': '2023-01-01T12:00:00.000Z',
        'imageUrls': 'not-a-list',
      };

      final report = UserReport.fromJson(json);

      expect(report.imageUrls, isEmpty);
    });

    test('toJson includes imageUrls', () {
      final report = UserReport(
        spotId: 'zone1',
        userId: 'user1',
        reportedCount: 5,
        timestamp: DateTime.parse('2023-01-01T12:00:00.000Z'),
        imageUrls: ['https://example.com/image1.jpg'],
      );

      final json = report.toJson();

      expect(json['imageUrls'], ['https://example.com/image1.jpg']);
    });

    test('toJson with empty imageUrls', () {
      final report = UserReport(
        spotId: 'zone1',
        userId: 'user1',
        reportedCount: 5,
        timestamp: DateTime.parse('2023-01-01T12:00:00.000Z'),
      );

      final json = report.toJson();

      expect(json['imageUrls'], isEmpty);
    });
  });
}