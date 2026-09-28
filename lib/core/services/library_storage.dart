/// Library Storage Service
///
/// Persists user settings and the reading history (books and their reading
/// position) on the device. Book texts are stored too, so recently read
/// books can be reopened - also on web, where there is no file path.
///
/// Books are identified by a hash of their text, so importing the same file
/// again resumes where reading stopped.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/book.dart';
import '../models/rsvp_settings.dart';

/// Storage for settings and reading progress
abstract class LibraryStorage {
  /// Maximum number of books kept in the reading history
  static const maxBooks = 20;

  // Storage primitives implemented by the backends below
  Map<dynamic, dynamic>? _getSettings();
  Future<void> _putSettings(Map<String, dynamic> value);
  Iterable<Map<dynamic, dynamic>> _getBooks();
  Map<dynamic, dynamic>? _getBook(String id);
  Future<void> _putBook(String id, Map<String, dynamic> value);
  Future<void> _deleteBook(String id);
  Future<String?> _getText(String id);
  Future<void> _putText(String id, String text);

  /// Stable id for a text: the same content always gets the same id
  static String idFor(String content) => sha1.convert(utf8.encode(content)).toString();

  /// Saved settings, or defaults when nothing was saved yet
  RSVPSettings loadSettings() {
    final map = _getSettings();
    return map == null ? const RSVPSettings() : RSVPSettings.fromMap(map);
  }

  /// Save settings
  Future<void> saveSettings(RSVPSettings settings) => _putSettings(settings.toMap());

  /// Books in the reading history, most recently read first
  List<Book> recentBooks() {
    return _getBooks().map(Book.fromMap).toList()
      ..sort((a, b) => (b.lastReadAt ?? b.importedAt).compareTo(a.lastReadAt ?? a.importedAt));
  }

  /// Find the stored book for [content], or add it to the history
  ///
  /// The returned book carries the saved reading position.
  Future<Book> openBook({
    required String content,
    required String title,
    required BookFormat format,
  }) async {
    final id = idFor(content);
    final existing = _getBook(id);
    final now = DateTime.now();

    final book = existing != null
        ? Book.fromMap(existing).copyWith(lastReadAt: now)
        : Book(id: id, title: title, format: format, importedAt: now, lastReadAt: now);

    await _putBook(id, book.toMap());
    if (existing == null) {
      await _putText(id, content);
      await _trimHistory();
    }

    return book;
  }

  /// Text of a stored book
  Future<String?> loadText(String bookId) => _getText(bookId);

  /// Save the reading position of a book
  ///
  /// [wordIndex] equal to [totalWords] marks the book as finished.
  Future<void> saveProgress(
    String bookId, {
    required int wordIndex,
    required int totalWords,
  }) async {
    final map = _getBook(bookId);
    if (map == null) return;

    final book = Book.fromMap(map).copyWith(
      currentWordIndex: wordIndex,
      totalWords: totalWords,
      lastReadAt: DateTime.now(),
    );
    await _putBook(bookId, book.toMap());
  }

  /// Remove a book and its text from the history
  Future<void> deleteBook(String bookId) => _deleteBook(bookId);

  Future<void> _trimHistory() async {
    for (final book in recentBooks().skip(maxBooks)) {
      await deleteBook(book.id);
    }
  }
}

/// [LibraryStorage] backed by Hive (IndexedDB on web, files elsewhere)
class HiveLibraryStorage extends LibraryStorage {
  final Box<dynamic> _settings;
  final Box<dynamic> _books;
  final LazyBox<String> _texts;

  HiveLibraryStorage._(this._settings, this._books, this._texts);

  static const _settingsKey = 'settings';

  /// Open the storage boxes
  ///
  /// [path] overrides the storage directory (used by tests).
  static Future<HiveLibraryStorage> open({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }

    return HiveLibraryStorage._(
      await Hive.openBox<dynamic>('settings'),
      await Hive.openBox<dynamic>('books'),
      // Lazy: texts are only loaded when a book is opened
      await Hive.openLazyBox<String>('book_texts'),
    );
  }

  @override
  Map<dynamic, dynamic>? _getSettings() => _settings.get(_settingsKey) as Map<dynamic, dynamic>?;

  @override
  Future<void> _putSettings(Map<String, dynamic> value) => _settings.put(_settingsKey, value);

  @override
  Iterable<Map<dynamic, dynamic>> _getBooks() => _books.values.whereType<Map<dynamic, dynamic>>();

  @override
  Map<dynamic, dynamic>? _getBook(String id) => _books.get(id) as Map<dynamic, dynamic>?;

  @override
  Future<void> _putBook(String id, Map<String, dynamic> value) => _books.put(id, value);

  @override
  Future<void> _deleteBook(String id) async {
    await _books.delete(id);
    await _texts.delete(id);
  }

  @override
  Future<String?> _getText(String id) => _texts.get(id);

  @override
  Future<void> _putText(String id, String text) => _texts.put(id, text);
}

/// In-memory [LibraryStorage]
///
/// Used when persistent storage is unavailable (e.g. blocked browser
/// storage) and in tests. Nothing survives an app restart.
class InMemoryLibraryStorage extends LibraryStorage {
  Map<String, dynamic>? _settings;
  final _books = <String, Map<String, dynamic>>{};
  final _texts = <String, String>{};

  @override
  Map<dynamic, dynamic>? _getSettings() => _settings;

  @override
  Future<void> _putSettings(Map<String, dynamic> value) async => _settings = value;

  @override
  Iterable<Map<dynamic, dynamic>> _getBooks() => _books.values;

  @override
  Map<dynamic, dynamic>? _getBook(String id) => _books[id];

  @override
  Future<void> _putBook(String id, Map<String, dynamic> value) async => _books[id] = value;

  @override
  Future<void> _deleteBook(String id) async {
    _books.remove(id);
    _texts.remove(id);
  }

  @override
  Future<String?> _getText(String id) async => _texts[id];

  @override
  Future<void> _putText(String id, String text) async => _texts[id] = text;
}
