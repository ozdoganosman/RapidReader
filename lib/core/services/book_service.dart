/// Book Service
///
/// The bundled library: the Turkish texts in assets/books/ and the English
/// ones in assets/books/en/ (same file names), chosen by the app's language.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/book.dart';
import 'app_language.dart';
import 'book_index.dart';

/// Service for loading pre-bundled books from assets/books/ folder
class BookService {
  /// Display names of the bundled series in each language (file names are
  /// ASCII)
  static const _seriesDisplayNames = {
    'tr': {
      'kuran': "Kur'an-ı Kerim",
      'attc': 'İki Şehrin Hikâyesi',
      'donusum': 'Dönüşüm',
      'omerseyfettin': 'Ömer Seyfettin Hikâyeleri',
    },
    'en': {
      'kuran': "The Qur'an",
      'attc': 'A Tale of Two Cities',
      'donusum': 'The Metamorphosis',
      'omerseyfettin': 'Stories by Ömer Seyfettin',
    },
  };

  /// Name to show for a series, e.g. "ATTC" -> "İki Şehrin Hikâyesi"
  static String seriesDisplayName(String seriesName, {String? language}) =>
      _seriesDisplayNames[language ?? AppLanguage.current]?[seriesName.toLowerCase()] ?? seriesName;

  /// Folder of the bundled texts in [language]
  static String folderFor(String language) => language == 'en' ? 'assets/books/en' : 'assets/books';

  /// Cover image extensions, in order of preference
  static const _coverExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

  /// Index of the bundled Turkish texts, built by tool/build_book_index.dart
  static const indexAsset = 'assets/books/index.json';

  /// Load the library in [language] (default: the app's): every text listed
  /// in the folder's index.json with its cover image (a series cover like
  /// "Donusum.jpg" is used for all its chapters). The texts themselves are
  /// loaded on demand ([loadContent]).
  static Future<List<Book>> loadBooks({String? language}) async {
    final books = <Book>[];
    final lang = language ?? AppLanguage.current;
    final folder = folderFor(lang);

    try {
      // List the bundled assets (AssetManifest.json is being removed from
      // Flutter builds, so use the AssetManifest API)
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();

      String? coverFor(String name) {
        for (final extension in _coverExtensions) {
          final path = '$folder/$name$extension';
          if (assets.contains(path)) return path;
        }
        return null;
      }

      final entries = BookIndex.decode(await rootBundle.loadString('$folder/index.json'));
      for (final entry in entries) {
        final name = entry.file.replaceAll('.txt', '');

        // Series and chapter from the file name: "ATTC_1" or "Donusum 1"
        String? seriesName;
        int? chapterNumber;
        final match = RegExp(r'^(.+?)[\s_]+(\d+)$').firstMatch(name);
        if (match != null) {
          seriesName = match.group(1)?.trim();
          chapterNumber = int.tryParse(match.group(2) ?? '');
        }

        // The English texts have their own reading positions
        final id = name.replaceAll(' ', '_').toLowerCase();
        books.add(Book(
          id: lang == 'en' ? 'en_$id' : id,
          title: entry.title,
          author: entry.author,
          category: 'Edebiyat',
          coverColor: '#8B4513', // Brown color for classic literature
          contentAsset: '$folder/${entry.file}',
          knownWordCount: entry.words,
          // Cover: the series cover if there is one, else the book's own cover
          coverAsset: (seriesName != null ? coverFor(seriesName) : null) ?? coverFor(name),
          seriesName: seriesName,
          chapterNumber: chapterNumber,
        ));
      }
    } catch (e) {
      debugPrint('BookService error: $e');
    }

    return books;
  }

  /// The text of [book]: bundled texts are read from their asset
  static Future<String> loadContent(Book book) {
    final asset = book.contentAsset;
    if (asset == null) return Future.value(book.content);
    return rootBundle.loadString(asset);
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
