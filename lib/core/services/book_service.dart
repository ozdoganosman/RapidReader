/// Book Service
///
/// Automatically scans and loads books from assets/books/ folder.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/book.dart';

/// Service for loading pre-bundled books from assets/books/ folder
class BookService {
  /// Load all books from assets/books/ folder
  /// Scans for .txt files and their corresponding .png cover images
  static Future<List<Book>> loadBooks() async {
    final books = <Book>[];

    try {
      // Load AssetManifest to get list of all assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Find all .txt files in assets/books/
      final bookFiles = manifestMap.keys
          .where((path) => path.startsWith('assets/books/') && path.endsWith('.txt'))
          .toList();

      for (final filePath in bookFiles) {
        // Read book content
        final content = await rootBundle.loadString(filePath);

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

        // Check for cover image (using file name, not display title)
        final coverPath = 'assets/books/$fileNameWithoutExt.png';
        String? imageBase64;

        if (manifestMap.containsKey(coverPath)) {
          final ByteData bytes = await rootBundle.load(coverPath);
          final Uint8List list = bytes.buffer.asUint8List();
          imageBase64 = base64Encode(list);
        }

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
          imageBase64: imageBase64,
          seriesName: seriesName,
          chapterNumber: chapterNumber,
        ));
      }

      // Load series cover images (e.g., "Donusum.png", "ATTC.png")
      // and assign to the first chapter of each series
      final Map<String, List<Book>> seriesMap = {};
      for (final book in books) {
        if (book.seriesName != null) {
          seriesMap.putIfAbsent(book.seriesName!, () => []);
          seriesMap[book.seriesName!]!.add(book);
        }
      }

      for (final entry in seriesMap.entries) {
        final seriesName = entry.key;
        final chapters = entry.value;

        // Check if series cover exists (e.g., "Donusum.png")
        final seriesCoverPath = 'assets/books/$seriesName.png';
        if (manifestMap.containsKey(seriesCoverPath)) {
          final ByteData bytes = await rootBundle.load(seriesCoverPath);
          final Uint8List list = bytes.buffer.asUint8List();
          final seriesCoverBase64 = base64Encode(list);

          // Update all chapters with series cover
          for (int i = 0; i < chapters.length; i++) {
            final index = books.indexOf(chapters[i]);
            if (index != -1) {
              books[index] = Book(
                id: books[index].id,
                title: books[index].title,
                author: books[index].author,
                category: books[index].category,
                coverColor: books[index].coverColor,
                content: books[index].content,
                imageBase64: seriesCoverBase64, // Use series cover
                seriesName: books[index].seriesName,
                chapterNumber: books[index].chapterNumber,
              );
            }
          }
        }
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
