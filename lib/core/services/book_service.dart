/// Book Service
///
/// Automatically scans and loads books from assets/books/ folder.
library;

import 'package:flutter/services.dart';

import '../models/book.dart';

/// Service for loading pre-bundled books from assets/books/ folder
class BookService {
  /// Cover image extensions, in order of preference
  static const _coverExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  /// Load all books from assets/books/ folder
  /// Scans for .txt files and their corresponding cover images
  /// (a series cover like "Donusum.jpg" is used for all its chapters)
  static Future<List<Book>> loadBooks() async {
    final books = <Book>[];

    try {
      // List the bundled assets (AssetManifest.json is being removed from
      // Flutter builds, so use the AssetManifest API)
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();

      String? coverFor(String name) {
        for (final extension in _coverExtensions) {
          final path = 'assets/books/$name$extension';
          if (assets.contains(path)) return path;
        }
        return null;
      }

      // Find all .txt files in assets/books/
      final bookFiles = assets
          .where((path) => path.startsWith('assets/books/') && path.endsWith('.txt'))
          .toList()
        ..sort();

      // Read all books in parallel (on web every file is a separate request)
      final contents = await Future.wait(bookFiles.map(rootBundle.loadString));

      for (var i = 0; i < bookFiles.length; i++) {
        final filePath = bookFiles[i];
        final content = contents[i];

        // Extract book name from file path (e.g. "Donusum 1.txt" -> "Donusum 1")
        final fileName = filePath.split('/').last;
        final fileNameWithoutExt = fileName.replaceAll('.txt', '');

        // Read the first line of the book as the display title (with Turkish characters)
        // If empty, fall back to file name
        String displayTitle = fileNameWithoutExt;
        final lines = content.split('\n');
        if (lines.isNotEmpty) {
          final firstLine = lines.first.trim();
          if (firstLine.isNotEmpty) {
            displayTitle = firstLine;
          }
        }

        // Parse series name and chapter number from filename
        // Examples: "ATTC 1" or "ATTC_1" -> series="ATTC", chapter=1
        //           "Donusum 1" -> series="Donusum", chapter=1
        String? seriesName;
        int? chapterNumber;

        // Support both space and underscore as separators
        final filenameMatch = RegExp(r'^(.+?)[\s_]+(\d+)$').firstMatch(fileNameWithoutExt);
        if (filenameMatch != null) {
          seriesName = filenameMatch.group(1)?.trim();
          chapterNumber = int.tryParse(filenameMatch.group(2) ?? '');
        }

        // Cover: the series cover if there is one, else the book's own cover
        final coverAsset = (seriesName != null ? coverFor(seriesName) : null) ??
            coverFor(fileNameWithoutExt);

        // Read author from second line if available
        String author = 'Franz Kafka'; // Default
        if (lines.length > 1) {
          final secondLine = lines[1].trim();
          if (secondLine.isNotEmpty && !secondLine.startsWith('http') && secondLine.length < 100) {
            author = secondLine;
          }
        }

        // Create Book object
        books.add(Book(
          id: fileNameWithoutExt.replaceAll(' ', '_').toLowerCase(),
          title: displayTitle,
          author: author,
          category: 'Edebiyat',
          coverColor: '#8B4513', // Brown color for classic literature
          content: content,
          coverAsset: coverAsset,
          seriesName: seriesName,
          chapterNumber: chapterNumber,
        ));
      }
    } catch (e) {
      print('BookService error: $e');
    }

    return books;
  }

  /// Get a single book by ID
  static Future<Book?> getBook(String id) async {
    final books = await loadBooks();
    try {
      return books.firstWhere((book) => book.id == id);
    } catch (_) {
      return null;
    }
  }
}
