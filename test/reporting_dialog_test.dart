 import 'dart:io';
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:firebase_core/firebase_core.dart';
 import 'package:image_picker/image_picker.dart';
 import 'package:mockito/mockito.dart';
 import 'package:motorbike_parking_app/models/models.dart';
 import 'package:motorbike_parking_app/widgets/reporting_dialog.dart';
 import 'mocks.dart';

 void main() {
   setUpAll(() async {
     TestWidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: const FirebaseOptions(
         apiKey: 'test-api-key',
         appId: 'test-app-id',
         messagingSenderId: 'test-sender-id',
         projectId: 'test-project-id',
       ),
     );
   });
  late MockImagePicker mockImagePicker;
  late MockXFile mockXFile;

  setUp(() {
    mockImagePicker = MockImagePicker();
    mockXFile = MockXFile();
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
                builder: (_) => ReportingDialog(zone: testZone, imagePicker: mockImagePicker),
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

    testWidgets('slider updates current count display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(zone: testZone, imagePicker: mockImagePicker),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Current bike count: 5'), findsOneWidget); // Initial value

      // Note: Testing slider interaction is complex and may require more setup
      // This basic test ensures the dialog renders correctly
    });

    testWidgets('add photo button picks image successfully', (WidgetTester tester) async {
      when(mockImagePicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => mockXFile);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(zone: testZone, imagePicker: mockImagePicker),
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

    testWidgets('image picker failure shows error', (WidgetTester tester) async {
      when(mockImagePicker.pickImage(source: ImageSource.camera))
          .thenThrow(Exception('Camera not available'));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportingDialog(zone: testZone, imagePicker: mockImagePicker),
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

      expect(find.text('Failed to pick image: Exception: Camera not available'), findsOneWidget);
    });
  });
}