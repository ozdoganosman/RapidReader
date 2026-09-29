import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/services/book_index.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';

/// The Turkish and the English library
const _folders = ['assets/books', 'assets/books/en'];

List<File> _texts(String folder) =>
    Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.txt')).toList();

void main() {
  for (final folder in _folders) {
    test('$folder/index.json is up to date', () {
      final texts = {
        for (final file in _texts(folder)) file.uri.pathSegments.last: file.readAsStringSync(),
      };
      final expected = BookIndex.encode(BookIndex.build(texts));

      expect(
        File('$folder/index.json').readAsStringSync(),
        expected,
        reason: 'Run `dart run tool/build_book_index.dart` after changing $folder/',
      );
    });
  }

  test('the English library has the same texts as the Turkish one', () {
    String names(String folder) => (_texts(folder).map((f) => f.uri.pathSegments.last).toList()..sort()).join(',');
    expect(names('assets/books/en'), names('assets/books'));
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
    for (final file in _folders.expand(_texts)) {
      final text = file.readAsStringSync();
      expect(Book.countWords(text), TextParser.parse(text).length, reason: file.path);
    }
  });
}
