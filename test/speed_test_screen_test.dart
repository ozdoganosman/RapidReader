import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/reading_stats.dart';
import 'package:rapid_reader/presentation/screens/speed_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('bundled speed tests are well formed', () {
    final data = jsonDecode(File('assets/content/speed_tests.json').readAsStringSync()) as Map<String, dynamic>;
    final tests = [for (final t in data['tests'] as List<dynamic>) SpeedTest.fromJson(t as Map<String, dynamic>)];
    expect(tests, hasLength(6));
    for (final test in tests) {
      expect(test.wordCount, inInclusiveRange(250, 400), reason: test.id);
      for (final q in test.questions) {
        expect(q.options, hasLength(4));
        expect(q.answer, inInclusiveRange(0, 3));
      }
    }
  });

  test('suggested speed follows comprehension', () {
    expect(suggestedWordsPerMinute(260, 100), 250);
    expect(suggestedWordsPerMinute(260, 50), 200);
    expect(suggestedWordsPerMinute(260, 25), 200);
    expect(suggestedWordsPerMinute(80, 100), RSVPSettings.minWordsPerMinute);
  });

  testWidgets('reading, answering and applying the suggested speed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const test = SpeedTest(
      id: 'x',
      title: 'Deneme',
      text: 'Bir iki üç dört beş.\n\nAltı yedi sekiz dokuz on.',
      questions: [
        SpeedTestQuestion(question: 'Soru bir?', options: ['A', 'B', 'C', 'D'], answer: 1),
        SpeedTestQuestion(question: 'Soru iki?', options: ['E', 'F', 'G', 'H'], answer: 0),
      ],
    );
    RSVPSettings? applied;
    await tester.pumpWidget(MaterialApp(
      home: SpeedTestScreen(
        settings: const RSVPSettings(),
        tests: const [test],
        onSettingsChanged: (s) => applied = s,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Deneme'), findsOneWidget);
    await tester.tap(find.text('Bitirdim'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.tap(find.text('F')); // wrong
    await tester.pump();
    await tester.tap(find.text('Sonucu Gör'));
    await tester.pumpAndSettle();

    expect(find.text('%50'), findsOneWidget);
    await tester.tap(find.text('Önerilen hızı kullan'));
    await tester.pump();
    expect(applied, isNotNull);

    final stats = await ReadingStats.load();
    expect(stats.speedTests.single.comprehension, 50);
  });
}
