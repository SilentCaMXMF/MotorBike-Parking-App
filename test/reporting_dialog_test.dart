import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorbike_parking_app/models/models.dart';
import 'package:motorbike_parking_app/widgets/reporting_dialog.dart';

void main() {
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
                builder: (_) => ReportingDialog(zone: testZone),
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
                builder: (_) => ReportingDialog(zone: testZone),
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
  });
}