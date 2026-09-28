import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/data/quran.dart';
import 'package:rapid_reader/presentation/screens/arabic_surah_screen.dart';
import 'package:rapid_reader/presentation/screens/chapter_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reading time follows the chosen speed', (tester) async {
    // 600 words: 2 minutes at 300 WPM, 1 minute at 600 WPM
    final chapter = Book(
      id: 'x_1',
      title: 'Birinci Bölüm',
      author: 'Yazar',
      category: 'Edebiyat',
      coverColor: '#8B4513',
      content: List.filled(600, 'kelime').join(' '),
      seriesName: 'X',
      chapterNumber: 1,
    );

    Future<void> pumpWith(int wpm) => tester.pumpWidget(MaterialApp(
          home: ChapterListScreen(
            seriesName: 'X',
            chapters: [chapter],
            settings: RSVPSettings(wordsPerMinute: wpm),
          ),
        ));

    await pumpWith(300);
    expect(find.textContaining('2 dk'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await pumpWith(600);
    expect(find.textContaining('1 dk'), findsOneWidget);
  });

  group('Quran', () {
    // The first three surahs in order of revelation: al-Alaq (96), al-Qalam (68), al-Muzzammil (73)
    final surahs = [
      for (final (n, name) in [(1, 'Alak Suresi (العلق)'), (2, 'Kalem Suresi (القلم)'), (3, 'Müzzemmil Suresi (المزمل)')])
        Book(
          id: 'kuran_$n',
          title: name,
          author: "Kur'an-ı Kerim",
          category: 'Edebiyat',
          coverColor: '#8B4513',
          content: 'metin',
          seriesName: quranSeriesName,
          chapterNumber: n,
        ),
    ];

    Future<void> pumpList(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        home: ChapterListScreen(seriesName: "Kur'an-ı Kerim", chapters: surahs, settings: const RSVPSettings()),
      ));
      await tester.pumpAndSettle();
    }

    List<String> listedTitles(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((t) => t.contains('Suresi'))
        .toList();

    testWidgets('search by name without circumflexes or by number', (tester) async {
      await pumpList(tester);

      await tester.enterText(find.byType(TextField), 'kalem');
      await tester.pump();
      expect(listedTitles(tester), ['Kalem Suresi (القلم)']);

      await tester.enterText(find.byType(TextField), '96'); // mushaf number of al-Alaq
      await tester.pump();
      expect(listedTitles(tester), ['Alak Suresi (العلق)']);
    });

    testWidgets('mushaf order sorts by surah number and is remembered', (tester) async {
      await pumpList(tester);
      expect(listedTitles(tester), ['Alak Suresi (العلق)', 'Kalem Suresi (القلم)', 'Müzzemmil Suresi (المزمل)']);

      await tester.tap(find.text('Mushaf sırası'));
      await tester.pumpAndSettle();
      expect(listedTitles(tester), ['Kalem Suresi (القلم)', 'Müzzemmil Suresi (المزمل)', 'Alak Suresi (العلق)']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('quran_mushaf_order'), isTrue);
    });

    testWidgets('opens the Arabic text of a surah', (tester) async {
      await pumpList(tester);

      await tester.tap(find.byTooltip('Arapça metin').first);
      await tester.pump();
      // The asset is read with real I/O
      final verses = (await tester.runAsync(() => loadArabicSurah(96)))!;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(find.byType(ArabicSurahScreen), findsOneWidget);
      // al-Alaq: basmala heading, then the first verse with its number
      expect(find.text(quranBasmala), findsOneWidget);
      expect(find.text('${verses.first} ﴿١﴾'), findsOneWidget);
    });
  });
}
