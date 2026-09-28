/// Book Index
///
/// Metadata of the bundled texts (assets/books/index.json), built by
/// tool/build_book_index.dart. The library is listed from this index; a
/// text itself is only loaded when it is opened.
library;

import 'dart:convert';

import '../models/book.dart';

/// One bundled text in the index
class BookIndexEntry {
  /// File name in assets/books/, e.g. "ATTC_2.txt"
  final String file;

  /// First line of the file
  final String title;

  /// Second line of the file, empty if it is not an author line
  final String author;

  /// Words in the whole file (same count as [Book.wordCount])
  final int words;

  const BookIndexEntry({
    required this.file,
    required this.title,
    required this.author,
    required this.words,
  });

  factory BookIndexEntry.fromJson(Map<String, dynamic> json) => BookIndexEntry(
        file: json['file'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        words: json['words'] as int,
      );

  Map<String, dynamic> toJson() => {'file': file, 'title': title, 'author': author, 'words': words};
}

class BookIndex {
  /// Index entries for the given texts ({file name: content}), sorted by file name
  static List<BookIndexEntry> build(Map<String, String> texts) {
    final files = texts.keys.toList()..sort();
    return [
      for (final file in files)
        BookIndexEntry(
          file: file,
          title: titleOf(file, texts[file]!),
          author: authorOf(texts[file]!),
          words: Book.countWords(texts[file]!),
        ),
    ];
  }

  /// The first line, or the file name without extension if it is empty
  static String titleOf(String file, String content) {
    final firstLine = content.split('\n').first.trim();
    return firstLine.isNotEmpty ? firstLine : file.replaceAll('.txt', '');
  }

  /// The second line when it looks like an author name, otherwise ''
  static String authorOf(String content) {
    final lines = content.split('\n');
    if (lines.length < 2) return '';
    final line = lines[1].trim();
    return line.isNotEmpty && !line.startsWith('http') && line.length < 100 ? line : '';
  }

  static String encode(List<BookIndexEntry> entries) =>
      '${const JsonEncoder.withIndent(' ').convert({'books': entries.map((e) => e.toJson()).toList()})}\n';

  static List<BookIndexEntry> decode(String json) => [
        for (final item in (jsonDecode(json) as Map<String, dynamic>)['books'] as List<dynamic>)
          BookIndexEntry.fromJson(item as Map<String, dynamic>),
      ];
}
