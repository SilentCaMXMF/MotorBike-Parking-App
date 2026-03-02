import 'package:flutter_test/flutter_test.dart';
import 'package:motorbike_parking_app/main.dart';

void main() {
  testWidgets('App smoke test - MyApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
  });
}
