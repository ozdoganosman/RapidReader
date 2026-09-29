// Builds the index.json of each library folder (assets/books/ for the
// Turkish texts, assets/books/en/ for the English ones): title, author and
// word count of every bundled text, so the app can list the library without
// loading all texts.
//
// Run after adding or changing a file in assets/books/ or assets/books/en/:
//   dart run tool/build_book_index.dart
// (test/book_index_test.dart fails when an index is out of date.)

import 'dart:io';

import 'package:rapid_reader/core/services/book_index.dart';

void main() {
  for (final folder in ['assets/books', 'assets/books/en']) {
    final entries = BookIndex.build({
      for (final file in Directory(folder).listSync().whereType<File>().where((f) => f.path.endsWith('.txt')))
        file.uri.pathSegments.last: file.readAsStringSync(),
    });
    File('$folder/index.json').writeAsStringSync(BookIndex.encode(entries));
    stdout.writeln('$folder/index.json: ${entries.length} texts, '
        '${entries.fold<int>(0, (sum, e) => sum + e.words)} words');
  }
}
