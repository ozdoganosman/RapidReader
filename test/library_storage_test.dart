import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rapid_reader/core/models/book.dart';
import 'package:rapid_reader/core/models/rsvp_settings.dart';
import 'package:rapid_reader/core/services/library_storage.dart';

void main() {
  group('RSVPSettings serialization', () {
    test('round-trips through a map', () {
      const settings = RSVPSettings(
        wordsPerMinute: 450,
        chunkSize: 2,
        adaptiveSpeed: false,
        fontSize: 40,
        microPauseInterval: 0,
        backgroundColor: 0xFFFBF0E4,
      );
      expect(RSVPSettings.fromMap(settings.toMap()), settings);
    });

    test('invalid or missing values fall back to safe values', () {
      final settings = RSVPSettings.fromMap(const {
        'wordsPerMinute': -100,
        'chunkSize': 9,
        'fontSize': 500,
        'microPauseInterval': 99,
        'adaptiveSpeed': 'yes',
      });
      expect(settings.wordsPerMinute, RSVPSettings.minWordsPerMinute);
      expect(settings.chunkSize, 3);
      expect(settings.fontSize, 60);
      expect(settings.microPauseInterval, 15);
      expect(settings.adaptiveSpeed, RSVPSettings.defaults.adaptiveSpeed);
    });
  });

  test('Book round-trips through a map', () {
    final book = Book(
      id: 'abc',
      title: 'Kitap',
      format: BookFormat.epub,
      importedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      lastReadAt: DateTime.fromMillisecondsSinceEpoch(2000),
      totalWords: 500,
      currentWordIndex: 120,
    );
    expect(Book.fromMap(book.toMap()), book);
  });

  group('LibraryStorage', () {
    late LibraryStorage storage;

    setUp(() => storage = InMemoryLibraryStorage());

    test('returns default settings until settings are saved', () async {
      expect(storage.loadSettings(), const RSVPSettings());

      await storage.saveSettings(const RSVPSettings(wordsPerMinute: 450));
      expect(storage.loadSettings().wordsPerMinute, 450);
    });

    test('opening the same text again resumes the saved position', () async {
      final book = await storage.openBook(content: 'Bir iki üç.', title: 'A', format: BookFormat.txt);
      await storage.saveProgress(book.id, wordIndex: 2, totalWords: 3);

      final again = await storage.openBook(content: 'Bir iki üç.', title: 'A (kopya)', format: BookFormat.txt);
      expect(again.id, book.id);
      expect(again.currentWordIndex, 2);
      expect(again.totalWords, 3);
      expect(storage.recentBooks(), hasLength(1));
      expect(await storage.loadText(book.id), 'Bir iki üç.');
    });

    test('lists the most recently read book first', () async {
      final first = await storage.openBook(content: 'birinci', title: '1', format: BookFormat.manual);
      await storage.openBook(content: 'ikinci', title: '2', format: BookFormat.manual);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await storage.saveProgress(first.id, wordIndex: 0, totalWords: 1);

      expect(storage.recentBooks().map((b) => b.title), ['1', '2']);
    });

    test('deleting a book removes its text', () async {
      final book = await storage.openBook(content: 'metin', title: 'M', format: BookFormat.manual);
      await storage.deleteBook(book.id);

      expect(storage.recentBooks(), isEmpty);
      expect(await storage.loadText(book.id), isNull);
    });

    test('keeps at most ${LibraryStorage.maxBooks} books', () async {
      for (var i = 0; i < LibraryStorage.maxBooks + 5; i++) {
        await storage.openBook(content: 'metin $i', title: '$i', format: BookFormat.manual);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      final books = storage.recentBooks();
      expect(books, hasLength(LibraryStorage.maxBooks));
      expect(books.first.title, '${LibraryStorage.maxBooks + 4}');
    });
  });

  group('HiveLibraryStorage', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('rapid_reader_test'));

    tearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('settings and progress survive reopening the storage', () async {
      var storage = await HiveLibraryStorage.open(path: dir.path);
      await storage.saveSettings(const RSVPSettings(wordsPerMinute: 600, chunkSize: 2));
      final book = await storage.openBook(content: 'Bir iki üç.', title: 'Deneme', format: BookFormat.pdf);
      await storage.saveProgress(book.id, wordIndex: 1, totalWords: 3);
      await Hive.close();

      storage = await HiveLibraryStorage.open(path: dir.path);
      expect(storage.loadSettings().wordsPerMinute, 600);
      expect(storage.loadSettings().chunkSize, 2);

      final books = storage.recentBooks();
      expect(books, hasLength(1));
      expect(books.single.title, 'Deneme');
      expect(books.single.format, BookFormat.pdf);
      expect(books.single.currentWordIndex, 1);
      expect(await storage.loadText(book.id), 'Bir iki üç.');
    });
  });
}
