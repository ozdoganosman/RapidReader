import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/ad_service.dart';
import 'package:rapid_reader/core/services/reading_storage.dart';
import 'package:rapid_reader/presentation/screens/reader_screen.dart';
import 'package:rapid_reader/presentation/widgets/orp_text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rapid_reader/l10n/app_localizations.dart';

// Non-mono family keeps the test offline (no font download)
const _settings = RSVPSettings(fontFamily: 'sans');

Future<void> _pumpReader(
  WidgetTester tester,
  String content, {
  RSVPSettings settings = _settings,
  ValueChanged<RSVPSettings>? onSettingsChanged,
}) async {
  _mockPlatform(tester);

  await tester.pumpWidget(MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ReaderScreen(content: content, settings: settings, onSettingsChanged: onSettingsChanged),
  ));
}

void _mockPlatform(WidgetTester tester) {
  // wakelock_plus talks to the platform through a pigeon channel
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );
  // reading positions
  SharedPreferences.setMockInitialValues({});
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

  testWidgets('with word groups the time estimate still counts words', (tester) async {
    await _pumpReader(tester, List.filled(60, 'kelime').join(' '), settings: _settings.copyWith(chunkSize: 2));

    // 60 words at 300 WPM, shown as 30 groups of two
    expect(find.text('Kalan: 0 dk 12 sn / Toplam: 0 dk 12 sn'), findsOneWidget);
    expect(find.text('1 / 30'), findsOneWidget);
  });

  test('word positions map to the token holding the word', () {
    // tokens of 2, 2, 1 and 3 words
    const wordsBefore = [0, 2, 4, 5, 8];
    expect([for (var w = 0; w < 8; w++) ReaderScreen.tokenIndexOfWord(wordsBefore, w)], [0, 0, 1, 1, 2, 3, 3, 3]);
    expect(ReaderScreen.tokenIndexOfWord(wordsBefore, 99), 3);
    expect(ReaderScreen.tokenIndexOfWord(const [0], 5), 0);
  });

  testWidgets('the reading position survives a chunk size change', (tester) async {
    _mockPlatform(tester);
    final text = List.generate(30, (i) => 'k$i').join(' ');
    final book = Book(id: 'b', title: 'B', author: '', category: '', coverColor: '#000000', content: text);
    // word 13 ("k13"), saved while reading word by word
    await ReadingStorage.saveProgress('b', const ReadingProgress(index: 13, total: 30));

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(content: text, settings: _settings.copyWith(chunkSize: 3), currentBook: book),
    ));
    await tester.pumpAndSettle();
    expect(find.text('5 / 10'), findsOneWidget); // the group "k12 k13 k14"
  });

  testWidgets('on a short window the controls stay above the word', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReader(tester, 'Birinci Bölüm');

    final word = tester.getRect(find.byType(RSVPDisplay));
    final wordTop = tester.getRect(find.byType(ORPTextWidget)).top;
    expect(tester.getRect(find.textContaining('Kalan:')).bottom, lessThan(wordTop));
    expect(tester.getRect(find.byIcon(Icons.play_circle)).bottom, lessThan(wordTop));
    expect(word.height, greaterThan(0));
  });

  testWidgets('a tap on the left edge goes back to the start of the sentence', (tester) async {
    _mockPlatform(tester);
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(content: 'Bir iki üç. Dört beş altı yedi.', settings: _settings, startIndex: 5),
    ));
    await tester.pump();
    expect(find.text('6 / 7'), findsOneWidget);

    await tester.tapAt(const Offset(20, 400));
    await tester.pump();
    expect(find.text('4 / 7'), findsOneWidget); // "Dört"

    await tester.tapAt(const Offset(20, 400));
    await tester.pump();
    expect(find.text('1 / 7'), findsOneWidget); // already there: the sentence before
  });

  testWidgets('gradual speed-up adds 10 WPM a minute up to the target', (tester) async {
    _mockPlatform(tester);
    final speeds = <int>[];
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(
        content: List.filled(2000, 'kelime').join(' '),
        settings: _settings.copyWith(wordsPerMinute: 300, speedRampTarget: 320, adaptiveSpeed: false),
        onSettingsChanged: (s) => speeds.add(s.wordsPerMinute),
      ),
    ));
    await tester.tap(find.byIcon(Icons.play_circle));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 50));
    }
    expect(speeds, [310, 320]);
    await tester.tapAt(const Offset(200, 400)); // pause
    await tester.pump(const Duration(seconds: 3));
  });

  group('completion', () {
    Book chapter(int number, String title) => Book(
          id: 'kuran_$number',
          title: title,
          author: '',
          category: 'Din',
          coverColor: '#000000',
          content: 'Bir iki üç.',
          seriesName: 'Kuran',
          chapterNumber: number,
        );

    // In mushaf order (numbers are the revelation order): Fatiha (5),
    // Bakara (87), ... Tebbet (6); in revelation order Tebbet follows Fatiha
    final fatiha = chapter(5, 'Fatiha Suresi');
    final chapters = [fatiha, chapter(87, 'Bakara Suresi'), chapter(6, 'Tebbet Suresi')];

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReaderScreen(content: fatiha.content, settings: _settings, currentBook: fatiha, seriesChapters: chapters),
      ));
      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Bölüm Tamamlandı!'), findsOneWidget);
    }

    testWidgets('"Sonraki Bölüm" follows the order of the chapter list', (tester) async {
      _mockPlatform(tester);
      await finish(tester);

      await tester.tap(find.text('Sonraki Bölüm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bakara Suresi'), findsOneWidget);
    });

    testWidgets('"Ana Sayfaya Dön" goes back to the library, past the chapter list', (tester) async {
      _mockPlatform(tester);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: navigatorKey,
          home: const Text('Kütüphane')));
      navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('Bölüm listesi')));
      navigatorKey.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(content: fatiha.content, settings: _settings),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump(const Duration(seconds: 10));

      await tester.tap(find.text('Ana Sayfaya Dön'));
      await tester.pumpAndSettle();
      expect(find.text('Kütüphane'), findsOneWidget);
      expect(find.text('Bölüm listesi'), findsNothing);
    });

    testWidgets('a tap beside the buttons does not restart the chapter', (tester) async {
      _mockPlatform(tester);
      await finish(tester);

      await tester.tapAt(const Offset(20, 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Bölüm Tamamlandı!'), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);
    });
  });
}
