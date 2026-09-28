import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/presentation/screens/reader_screen.dart';

const _settings = RSVPSettings();

Future<void> _pumpReader(WidgetTester tester, String content) async {
  // wakelock_plus talks to the platform through a pigeon channel
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );

  await tester.pumpWidget(MaterialApp(
    home: ReaderScreen(content: content, settings: _settings),
  ));
}

void main() {
  testWidgets('finishing the text shows completion without errors', (tester) async {
    await _pumpReader(tester, 'Bir iki üç.');

    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pump(const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
    expect(find.text('Okuma Tamamlandı!'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 2);
  });

  testWidgets('speed display stays within the supported range', (tester) async {
    await _pumpReader(tester, 'Bir iki üç.');

    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
    }
    expect(find.text('${RSVPSettings.minWordsPerMinute} WPM'), findsOneWidget);

    for (var i = 0; i < 40; i++) {
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
    }
    expect(find.text('${RSVPSettings.maxWordsPerMinute} WPM'), findsOneWidget);
  });
}
