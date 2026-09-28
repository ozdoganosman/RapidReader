import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/read_aloud_player.dart';
import 'package:rapid_reader/core/services/reading_storage.dart';
import 'package:rapid_reader/presentation/screens/reader_screen.dart';
import 'package:rapid_reader/presentation/screens/text_page_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_tts.dart';

// Non-mono family keeps the test offline (no font download)
const _settings = RSVPSettings(fontFamily: 'sans');
const _text = 'Birinci Bölüm\nBir iki üç dört.\nBeş altı yedi.\nSekiz dokuz on.';

Book _chapter(int number) => Book(
      id: 'seri_$number',
      title: 'Bölüm $number',
      author: '',
      category: '',
      coverColor: '#000000',
      content: _text,
      seriesName: 'Seri',
      chapterNumber: number,
    );

void _mockPlatform(WidgetTester tester) {
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );
  SharedPreferences.setMockInitialValues({});
}

Future<void> _pump(WidgetTester tester, {bool listen = false, Book? book, List<Book>? chapters}) async {
  await tester.pumpWidget(MaterialApp(
    home: TextPageScreen(
      content: _text,
      title: 'Seri - Bölüm 1',
      settings: _settings,
      currentBook: book,
      seriesChapters: chapters,
      listen: listen,
      playerBuilder: (paragraphs, rate) => ReadAloudPlayer(paragraphs: paragraphs, rate: rate, queue: true),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('plain text: the paragraphs as a page, no voice', (tester) async {
    _mockPlatform(tester);
    final tts = FakeTts(tester);
    await _pump(tester, book: _chapter(1), chapters: [_chapter(1), _chapter(2)]);

    expect(find.text('Bir iki üç dört.'), findsOneWidget);
    expect(find.text('Sekiz dokuz on.'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle), findsNothing);
    expect(find.text('Sonraki Bölüm'), findsOneWidget);
    expect(tts.spoken, isEmpty);
  });

  testWidgets('listening starts right away and highlights the word being read', (tester) async {
    _mockPlatform(tester);
    final tts = FakeTts(tester);
    await _pump(tester, listen: true);
    await tester.pump();

    expect(tts.spoken, ['Birinci Bölüm', 'Bir iki üç dört.', 'Beş altı yedi.', 'Sekiz dokuz on.']);
    expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    expect(find.text('Ses 1x'), findsOneWidget);

    await tts.start();
    await tts.complete();
    await tts.progress('Bir iki üç dört.', 4, 7); // "iki"
    final highlighted = <String>[];
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        if (span is TextSpan && span.style?.fontWeight == FontWeight.bold && span.text != null) {
          highlighted.add(span.text!);
        }
        return true;
      });
    }
    expect(highlighted, ['iki']);

    // Tap a paragraph to read from there
    tts.calls.clear();
    await tester.tap(find.text('Sekiz dokuz on.'));
    await tester.pump();
    await tester.pump();
    expect(tts.spoken, ['Sekiz dokuz on.']);

    await tester.tap(find.byIcon(Icons.pause_circle));
    await tester.pump();
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
  });

  testWidgets('listening goes on with the next chapter', (tester) async {
    _mockPlatform(tester);
    final tts = FakeTts(tester);
    await _pump(tester, listen: true, book: _chapter(1), chapters: [_chapter(1), _chapter(2)]);
    await tester.pump();

    await tts.start();
    for (var i = 0; i < 4; i++) {
      await tts.complete();
    }
    await tester.pumpAndSettle();
    expect(find.text('Seri - Bölüm 2'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle), findsOneWidget); // reading again
  });

  testWidgets('listening goes on where the chapter was left off', (tester) async {
    _mockPlatform(tester);
    final tts = FakeTts(tester);
    // word 7 ("Beş"): 2 + 4 words before the third paragraph
    await ReadingStorage.saveProgress('seri_1', const ReadingProgress(index: 7, total: 13));
    await _pump(tester, listen: true, book: _chapter(1));
    await tester.pump();

    expect(tts.spoken.first, 'Beş altı yedi.');
  });

  testWidgets('without a Turkish voice it says so', (tester) async {
    _mockPlatform(tester);
    FakeTts(tester).available = false;
    await _pump(tester, listen: true);
    await tester.pump();
    expect(find.textContaining('Türkçe ses bulunamadı'), findsOneWidget);
  });

  testWidgets('opening a chapter asks how to read it', (tester) async {
    _mockPlatform(tester);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => ReaderScreen.open(context, book: _chapter(1), title: 'Bölüm 1', settings: _settings),
          child: const Text('Aç'),
        ),
      ),
    ));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Hızlı Okuma'), findsOneWidget);
    expect(find.text('Düz Metin'), findsOneWidget);
    expect(find.text('Sesli Okuma'), findsOneWidget);

    await tester.tap(find.text('Düz Metin'));
    await tester.pumpAndSettle();
    expect(find.byType(TextPageScreen), findsOneWidget);
    expect(find.text('Beş altı yedi.'), findsOneWidget);
  });
}
