import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/presentation/screens/chapter_list_screen.dart';

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
}
