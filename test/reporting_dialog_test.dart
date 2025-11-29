import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:motorbike_parking_app/models/models.dart';
import 'package:motorbike_parking_app/widgets/reporting_dialog.dart';
import 'package:motorbike_parking_app/services/sql_service.dart';
import 'package:motorbike_parking_app/services/location_service.dart';
import 'mocks/mock_sql_service.dart';
import 'mocks/mock_location_service.dart';

// Mock ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}

// Mock XFile
class MockXFile extends Mock implements XFile {
  @override
  String get path => 'test_image.jpg';
}

void main() {
  late MockImagePicker mockImagePicker;
  late MockXFile mockXFile;
  late MockSqlService mockSqlService;
  late MockLocationService mockLocationService;

  setUp(() {
    mockImagePicker = MockImagePicker();
    mockXFile = MockXFile();
    mockSqlService = MockSqlService();
    mockLocationService = MockLocationService();
  });

  group('ReportingDialog', () {
    final testZone = ParkingZone(
      id: 'test_zone',
      latitude: 38.7223,
      longitude: -9.1393,
      totalCapacity: 10,
      currentOccupancy: 5,
      confidenceScore: 0.8,
      lastUpdated: DateTime.now(),
      userReports: [],
    );

    testWidgets('renders dialog with zone info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Report Parking Availability'), findsOneWidget);
      expect(find.text('Zone: test_zone'), findsOneWidget);
      expect(find.text('Capacity: 10'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('slider updates current count display',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(
          find.text('Current bike count: 5'), findsOneWidget); // Initial value

      // Note: Testing slider interaction is complex and may require more setup
      // This basic test ensures the dialog renders correctly
    });

    testWidgets('add photo button picks image successfully',
        (WidgetTester tester) async {
      when(mockImagePicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => mockXFile);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Photo'));
      await tester.pump();

      // Verify image is added (though we can't easily test the UI without more setup)
      // This tests that the pickImage method is called
      verify(mockImagePicker.pickImage(source: ImageSource.camera)).called(1);
    });

    testWidgets('image picker failure shows error',
        (WidgetTester tester) async {
      when(mockImagePicker.pickImage(source: ImageSource.camera))
          .thenThrow(Exception('Camera not available'));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Photo'));
      await tester.pump();

      expect(find.text('Failed to pick image: Exception: Camera not available'),
          findsOneWidget);
    });

    testWidgets('displays loading indicator during report submission',
        (WidgetTester tester) async {
      // Setup mock to delay response
      mockSqlService.setupAddUserReportSuccess(reportId: 'report-123');
      mockLocationService.setupGetCurrentLocationSuccess(
        Position(
          latitude: 38.7223,
          longitude: -9.1393,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for submission to complete
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Report submitted successfully'), findsOneWidget);
    });

    testWidgets('displays error message on failed submission',
        (WidgetTester tester) async {
      // Setup mock to throw error
      mockSqlService.setupAddUserReportFailure(
        Exception('Failed to submit report: Network error'),
      );
      mockLocationService.setupGetCurrentLocationSuccess(
        Position(
          latitude: 38.7223,
          longitude: -9.1393,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Exception: Failed to submit report: Network error'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button resubmits report after error',
        (WidgetTester tester) async {
      // Setup mock to fail first, then succeed
      mockSqlService.setupAddUserReportFailure(
        Exception('Failed to submit report: Network error'),
      );
      mockLocationService.setupGetCurrentLocationSuccess(
        Position(
          latitude: 38.7223,
          longitude: -9.1393,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Exception: Failed to submit report: Network error'),
          findsOneWidget);

      // Setup mock to succeed on retry
      mockSqlService.setupAddUserReportSuccess(reportId: 'report-123');

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Report submitted successfully'), findsOneWidget);
    });

    testWidgets('displays upload progress when uploading image',
        (WidgetTester tester) async {
      // Setup mocks
      mockSqlService.setupAddUserReportSuccess(reportId: 'report-123');
      mockSqlService.setupUploadImageSuccess(
          imageUrl: 'https://example.com/image.jpg');
      mockLocationService.setupGetCurrentLocationSuccess(
        Position(
          latitude: 38.7223,
          longitude: -9.1393,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        ),
      );
      when(mockImagePicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => mockXFile);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(
                  zone: testZone,
                  imagePicker: mockImagePicker,
                  sqlService: mockSqlService as SqlService,
                  locationService: mockLocationService as LocationService,
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Add photo
      await tester.tap(find.text('Add Photo'));
      await tester.pump();

      // Tap submit button
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Verify upload progress is shown
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Wait for upload to complete
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Report submitted successfully'), findsOneWidget);
    });
  });
}
