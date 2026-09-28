import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/main.dart';

void main() {
  testWidgets('App launches and shows the library', (WidgetTester tester) async {
    // The banner ad talks to the native AdMob plugin; answer its calls
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );

    // Build the app
    await tester.pumpWidget(const RapidReaderApp());

    // Books are loaded from the asset bundle in the background
    for (var i = 0; i < 50 && find.text('RapidReader').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }

    // Verify the app title is present once the library is shown
    expect(find.text('RapidReader'), findsOneWidget);
  });
}
