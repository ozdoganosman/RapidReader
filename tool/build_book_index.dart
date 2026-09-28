// Builds assets/books/index.json: title, author and word count of every
// bundled text, so the app can list the library without loading all texts.
//
// Run after adding or changing a file in assets/books/:
//   dart run tool/build_book_index.dart
// (test/book_index_test.dart fails when the index is out of date.)

import 'dart:io';

import 'package:rapid_reader/core/services/book_index.dart';

void main() {
  final dir = Directory('assets/books');
  final entries = BookIndex.build({
    for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.txt')))
      file.uri.pathSegments.last: file.readAsStringSync(),
  });
  File('assets/books/index.json').writeAsStringSync(BookIndex.encode(entries));
  stdout.writeln('assets/books/index.json: ${entries.length} texts, '
      '${entries.fold<int>(0, (sum, e) => sum + e.words)} words');
}
