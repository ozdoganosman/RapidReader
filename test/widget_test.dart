import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const RapidReaderApp());

    // Verify the app title is present
    expect(find.text('RapidReader'), findsOneWidget);
  });
}
