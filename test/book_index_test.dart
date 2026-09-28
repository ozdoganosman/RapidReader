import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/services/book_index.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';

void main() {
  test('assets/books/index.json is up to date', () {
    final texts = {
      for (final file in Directory('assets/books').listSync().whereType<File>().where((f) => f.path.endsWith('.txt')))
        file.uri.pathSegments.last: file.readAsStringSync(),
    };
    final expected = BookIndex.encode(BookIndex.build(texts));

    expect(
      File('assets/books/index.json').readAsStringSync(),
      expected,
      reason: 'Run `dart run tool/build_book_index.dart` after changing assets/books/',
    );
  });

  test('title and author come from the first two lines', () {
    final entries = BookIndex.build({
      'Seri_1.txt': 'Birinci Bölüm\nYazar Adı\n\nBir iki üç.',
      'Seri_2.txt': '\nhttps://example.com\nMetin',
    });

    expect(entries.map((e) => e.title), ['Birinci Bölüm', 'Seri_2']);
    expect(entries.map((e) => e.author), ['Yazar Adı', '']);
    expect(entries.first.words, 7);
  });

  test('the listed word counts are the words the reader shows', () {
    // Standalone punctuation belongs to the next word, as in the reader
    expect(Book.countWords('Bir — iki "üç" .\n* * *\n\nDört'), 5);
    for (final file in Directory('assets/books').listSync().whereType<File>().where((f) => f.path.endsWith('.txt'))) {
      final text = file.readAsStringSync();
      expect(Book.countWords(text), TextParser.parse(text).length, reason: file.path);
    }
  });
}
