import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/ad_service.dart';
import 'package:rapid_reader/presentation/screens/reader_screen.dart';

// Non-mono family keeps the test offline (no font download)
const _settings = RSVPSettings(fontFamily: 'sans');

Future<void> _pumpReader(
  WidgetTester tester,
  String content, {
  ValueChanged<RSVPSettings>? onSettingsChanged,
}) async {
  // wakelock_plus talks to the platform through a pigeon channel
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );

  await tester.pumpWidget(MaterialApp(
    home: ReaderScreen(content: content, settings: _settings, onSettingsChanged: onSettingsChanged),
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

  testWidgets('a finished chapter counts once for the interstitial ad', (tester) async {
    final before = AdService().readingSessionCount;
    await _pumpReader(tester, 'Bir iki üç.');

    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pump(const Duration(seconds: 10));

    expect(AdService().readingSessionCount, (before + 1) % 3);
  });

  group('read-aloud', () {
    late List<String> spoken;

    void mockVoice(WidgetTester tester, {required bool available}) {
      spoken = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
        switch (call.method) {
          case 'isLanguageAvailable':
            return available;
          case 'speak':
            spoken.add(call.arguments as String);
            return Completer<int>().future; // still speaking
        }
        return 1;
      });
    }

    testWidgets('the headphones button reads the text aloud', (tester) async {
      mockVoice(tester, available: true);
      RSVPSettings? changed;
      await _pumpReader(tester, 'Bir iki üç.', onSettingsChanged: (s) => changed = s);

      await tester.tap(find.byIcon(Icons.headphones_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.headphones), findsOneWidget);
      expect(find.text('Ses 1x'), findsOneWidget);
      expect(changed?.readAloud, isTrue);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(find.text('Ses 1,25x'), findsOneWidget);
      expect(changed?.speechRate, 1.25);

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump();
      await tester.pump();
      expect(spoken, ['Bir iki üç.']);

      // The words follow the voice, not the timer
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Okuma Tamamlandı!'), findsNothing);

      await tester.tap(find.byIcon(Icons.headphones));
      await tester.pump();
      expect(find.text('${_settings.wordsPerMinute} WPM'), findsOneWidget);
      expect(changed?.readAloud, isFalse);
    });

    testWidgets('without a Turkish voice it says so and keeps RSVP', (tester) async {
      mockVoice(tester, available: false);
      await _pumpReader(tester, 'Bir iki üç.');

      await tester.tap(find.byIcon(Icons.headphones_outlined));
      await tester.pumpAndSettle();
      expect(find.textContaining('Türkçe ses bulunamadı'), findsOneWidget);
      expect(find.text('${_settings.wordsPerMinute} WPM'), findsOneWidget);
    });
  });
}
