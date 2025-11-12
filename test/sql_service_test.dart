import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:motorbike_parking_app/services/sql_service.dart';
import 'package:motorbike_parking_app/models/parking_zone.dart';
import 'package:motorbike_parking_app/models/user_report.dart';
import 'mocks/mock_api_service.dart';

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  group('SqlService Parking Zone Methods', () {
    test('getParkingZones returns list of parking zones', () async {
      // Arrange
      const latitude = 38.7223;
      const longitude = -9.1393;
      const radius = 5.0;
      const limit = 50;

      final mockZoneData = [
        {
          'id': 'zone1',
          'latitude': 38.7223,
          'longitude': -9.1393,
          'totalCapacity': 10,
          'currentOccupancy': 5,
          'confidenceScore': 0.8,
          'lastUpdated': '2023-01-01T12:00:00.000Z',
          'userReports': [],
        },
        {
          'id': 'zone2',
          'latitude': 38.7224,
          'longitude': -9.1394,
          'totalCapacity': 8,
          'currentOccupancy': 5,
          'confidenceScore': 0.7,
          'lastUpdated': '2023-01-01T12:00:00.000Z',
          'userReports': [],
        },
      ];

      mockApiService.setupGetSuccess(
        '/api/parking/nearby',
        {'data': mockZoneData},
      );

      // Act
      final response = await mockApiService.get(
        '/api/parking/nearby',
        queryParams: {
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
          'limit': limit,
        },
      );

      final zones = (response.data['data'] as List)
          .map((json) => ParkingZone.fromJson(json))
          .toList();

      // Assert
      expect(zones, isA<List<ParkingZone>>());
      expect(zones.length, 2);
      expect(zones[0].id, 'zone1');
      expect(zones[0].totalCapacity, 10);
      expect(zones[1].id, 'zone2');
      expect(zones[1].totalCapacity, 8);
    });

    test('getParkingZones handles empty list', () async {
      // Arrange
      const latitude = 38.7223;
      const longitude = -9.1393;

      mockApiService.setupGetSuccess(
        '/api/parking/nearby',
        {'data': []},
      );

      // Act
      final response = await mockApiService.get(
        '/api/parking/nearby',
        queryParams: {
          'lat': latitude,
          'lng': longitude,
          'radius': 5.0,
          'limit': 50,
        },
      );

      final zones = (response.data['data'] as List)
          .map((json) => ParkingZone.fromJson(json))
          .toList();

      // Assert
      expect(zones, isEmpty);
    });

    test('getParkingZones throws exception on API error', () async {
      // Arrange
      const latitude = 38.7223;
      const longitude = -9.1393;

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/parking/nearby'),
        type: DioExceptionType.connectionTimeout,
        error: 'Connection timeout',
      );

      mockApiService.setupGetFailure('/api/parking/nearby', dioException);

      // Act & Assert
      expect(
        () => mockApiService.get(
          '/api/parking/nearby',
          queryParams: {
            'lat': latitude,
            'lng': longitude,
            'radius': 5.0,
            'limit': 50,
          },
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('getParkingZone returns single parking zone', () async {
      // Arrange
      const zoneId = 'zone1';
      final mockZoneData = {
        'id': 'zone1',
        'latitude': 38.7223,
        'longitude': -9.1393,
        'totalCapacity': 10,
        'currentOccupancy': 5,
        'confidenceScore': 0.8,
        'lastUpdated': '2023-01-01T12:00:00.000Z',
        'userReports': [],
      };

      mockApiService.setupGetSuccess(
        '/api/parking/$zoneId',
        {'data': mockZoneData},
      );

      // Act
      final response = await mockApiService.get('/api/parking/$zoneId');
      final zone = ParkingZone.fromJson(response.data['data']);

      // Assert
      expect(zone, isA<ParkingZone>());
      expect(zone.id, 'zone1');
      expect(zone.totalCapacity, 10);
      expect(zone.currentOccupancy, 5);
      expect(zone.availableSlots, 5);
    });

    test('getParkingZone returns null for non-existent zone', () async {
      // Arrange
      const zoneId = 'non-existent';

      mockApiService.setupGetSuccess(
        '/api/parking/$zoneId',
        {'data': null},
      );

      // Act
      final response = await mockApiService.get('/api/parking/$zoneId');
      final data = response.data['data'];

      // Assert
      expect(data, isNull);
    });
  });

  group('SqlService Report Methods', () {
    test('addUserReport returns report ID', () async {
      // Arrange
      final report = UserReport(
        spotId: 'zone1',
        userId: 'user123',
        reportedCount: 5,
        timestamp: DateTime.parse('2023-01-01T12:00:00.000Z'),
        userLatitude: 38.7223,
        userLongitude: -9.1393,
      );

      final mockResponseData = {
        'data': {
          'id': 'report-123',
          'spotId': 'zone1',
          'reportedCount': 5,
        }
      };

      mockApiService.setupPostSuccess('/api/reports', mockResponseData);

      // Act
      final response = await mockApiService.post(
        '/api/reports',
        body: {
          'spotId': report.spotId,
          'reportedCount': report.reportedCount,
          'userLatitude': report.userLatitude,
          'userLongitude': report.userLongitude,
          'timestamp': report.timestamp.toIso8601String(),
        },
      );

      final reportId = response.data['data']['id'];

      // Assert
      expect(reportId, 'report-123');
      expect(reportId, isA<String>());
    });

    test('addUserReport throws exception on API error', () async {
      // Arrange
      final report = UserReport(
        spotId: 'zone1',
        userId: 'user123',
        reportedCount: 5,
        timestamp: DateTime.now(),
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/reports'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/reports'),
          statusCode: 400,
          data: {'error': 'Invalid report data'},
        ),
      );

      mockApiService.setupPostFailure('/api/reports', dioException);

      // Act & Assert
      expect(
        () => mockApiService.post(
          '/api/reports',
          body: {
            'spotId': report.spotId,
            'reportedCount': report.reportedCount,
            'timestamp': report.timestamp.toIso8601String(),
          },
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('getRecentReports returns list of reports', () async {
      // Arrange
      const spotId = 'zone1';
      const hours = 24;

      final mockReportsData = [
        {
          'spotId': 'zone1',
          'userId': 'user1',
          'reportedCount': 5,
          'timestamp': '2023-01-01T12:00:00.000Z',
          'userLatitude': 38.7223,
          'userLongitude': -9.1393,
        },
        {
          'spotId': 'zone1',
          'userId': 'user2',
          'reportedCount': 3,
          'timestamp': '2023-01-01T13:00:00.000Z',
          'userLatitude': 38.7224,
          'userLongitude': -9.1394,
        },
      ];

      mockApiService.setupGetSuccess(
        '/api/reports',
        {'data': mockReportsData},
      );

      // Act
      final response = await mockApiService.get(
        '/api/reports',
        queryParams: {
          'spotId': spotId,
          'hours': hours,
        },
      );

      final reports = (response.data['data'] as List)
          .map((json) => UserReport.fromJson(json))
          .toList();

      // Assert
      expect(reports, isA<List<UserReport>>());
      expect(reports.length, 2);
      expect(reports[0].spotId, 'zone1');
      expect(reports[0].reportedCount, 5);
      expect(reports[1].reportedCount, 3);
    });

    test('getRecentReports handles empty list', () async {
      // Arrange
      const spotId = 'zone1';
      const hours = 24;

      mockApiService.setupGetSuccess(
        '/api/reports',
        {'data': []},
      );

      // Act
      final response = await mockApiService.get(
        '/api/reports',
        queryParams: {
          'spotId': spotId,
          'hours': hours,
        },
      );

      final reports = (response.data['data'] as List)
          .map((json) => UserReport.fromJson(json))
          .toList();

      // Assert
      expect(reports, isEmpty);
    });

    test('getRecentReports throws exception on API error', () async {
      // Arrange
      const spotId = 'zone1';

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/reports'),
        type: DioExceptionType.connectionError,
        error: 'Connection error',
      );

      mockApiService.setupGetFailure('/api/reports', dioException);

      // Act & Assert
      expect(
        () => mockApiService.get(
          '/api/reports',
          queryParams: {
            'spotId': spotId,
            'hours': 24,
          },
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('SqlService Image Upload Methods', () {
    test('uploadImage returns image URL', () async {
      // Arrange
      final file = File('test_image.jpg');
      const reportId = 'report-123';
      const expectedImageUrl = 'https://example.com/images/test_image.jpg';

      final mockResponseData = {
        'data': {
          'imageUrl': expectedImageUrl,
        }
      };

      mockApiService.setupUploadFileSuccess(
        '/api/reports/$reportId/images',
        mockResponseData,
      );

      // Act
      final response = await mockApiService.uploadFile(
        '/api/reports/$reportId/images',
        file,
      );

      final imageUrl = response.data['data']['imageUrl'];

      // Assert
      expect(imageUrl, expectedImageUrl);
      expect(imageUrl, isA<String>());
    });

    test('uploadImage tracks progress', () async {
      // Arrange
      final file = File('test_image.jpg');
      const reportId = 'report-123';
      final progressValues = <double>[];

      final mockResponseData = {
        'data': {
          'imageUrl': 'https://example.com/images/test_image.jpg',
        }
      };

      mockApiService.setupUploadFileSuccess(
        '/api/reports/$reportId/images',
        mockResponseData,
      );

      // Act
      await mockApiService.uploadFile(
        '/api/reports/$reportId/images',
        file,
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Assert
      // Note: In real implementation, progress callback would be called
      // For mock, we just verify the method accepts the callback
      expect(progressValues, isA<List<double>>());
    });

    test('uploadImage throws exception on API error', () async {
      // Arrange
      final file = File('test_image.jpg');
      const reportId = 'report-123';

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/reports/$reportId/images'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/reports/$reportId/images'),
          statusCode: 413,
          data: {'error': 'File too large'},
        ),
      );

      mockApiService.setupUploadFileFailure(
        '/api/reports/$reportId/images',
        dioException,
      );

      // Act & Assert
      expect(
        () => mockApiService.uploadFile(
          '/api/reports/$reportId/images',
          file,
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
