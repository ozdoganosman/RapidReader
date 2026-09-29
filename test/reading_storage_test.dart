import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/reading_storage.dart';
import 'package:rapid_reader/presentation/screens/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rapid_reader/l10n/app_localizations.dart';

const _text = 'Bir iki üç dört beş altı yedi sekiz dokuz on.';

const _book = Book(
  id: 'test_1',
  title: 'Deneme',
  author: 'Yazar',
  category: 'Edebiyat',
  coverColor: '#8B4513',
  content: _text,
);

Future<void> _pumpReader(
  WidgetTester tester, {
  ValueChanged<RSVPSettings>? onSettingsChanged,
}) async {
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ReaderScreen(
      content: _text,
      title: 'Deneme',
      currentBook: _book,
      onSettingsChanged: onSettingsChanged,
    ),
  ));
  // Let the saved position load
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RSVPSettings serialization', () {
    test('round-trips through a map', () {
      const settings = RSVPSettings(
        wordsPerMinute: 450,
        chunkSize: 2,
        adaptiveSpeed: false,
        fontSize: 40,
        fontFamily: 'Lato',
        microPauseInterval: 0,
        backgroundColor: 0xFFFBF0E4,
      );
      expect(RSVPSettings.fromMap(settings.toMap()), settings);
    });

    test('invalid or missing values fall back to safe values', () {
      final settings = RSVPSettings.fromMap(const {
        'wordsPerMinute': -100,
        'chunkSize': 9,
        'fontSize': 500,
        'microPauseInterval': 99,
        'adaptiveSpeed': 'yes',
      });
      expect(settings.wordsPerMinute, RSVPSettings.minWordsPerMinute);
      expect(settings.chunkSize, 3);
      expect(settings.fontSize, 60);
      expect(settings.microPauseInterval, 15);
      expect(settings.adaptiveSpeed, RSVPSettings.defaults.adaptiveSpeed);
    });
  });

  group('ReadingStorage', () {
    test('returns defaults until settings are saved', () async {
      expect(await ReadingStorage.loadSettings(), const RSVPSettings());

      await ReadingStorage.saveSettings(const RSVPSettings(wordsPerMinute: 450));
      expect((await ReadingStorage.loadSettings()).wordsPerMinute, 450);
    });

    test('saves the reading position per book', () async {
      expect(await ReadingStorage.loadProgress('a'), isNull);

      await ReadingStorage.saveProgress('a', const ReadingProgress(index: 12, total: 40));
      final progress = await ReadingStorage.loadProgress('a');
      expect(progress?.index, 12);
      expect(progress?.total, 40);
      expect(await ReadingStorage.loadProgress('b'), isNull);
    });
  });

  group('ReaderScreen progress', () {
    testWidgets('continues at the saved word', (tester) async {
      await ReadingStorage.saveProgress(_book.id, const ReadingProgress(index: 4, total: 10));

      await _pumpReader(tester);

      expect(find.text('5 / 10'), findsOneWidget);
    });

    testWidgets('a finished book starts again from the beginning', (tester) async {
      await ReadingStorage.saveProgress(_book.id, const ReadingProgress(index: 10, total: 10));

      await _pumpReader(tester);

      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets('saves the position when the reader closes', (tester) async {
      await _pumpReader(tester);

      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.tap(find.byIcon(Icons.pause_circle));
      await tester.pump(const Duration(seconds: 3)); // let the controls timer finish
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      final saved = await tester.runAsync(() => ReadingStorage.loadProgress(_book.id));
      expect(saved, isNotNull);
      expect(saved!.index, greaterThan(0));
      expect(saved.total, 10);
    });

    testWidgets('reports speed changes so they can be saved', (tester) async {
      RSVPSettings? changed;
      await _pumpReader(tester, onSettingsChanged: (s) => changed = s);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(changed?.wordsPerMinute, 350);
    });
  });
}
