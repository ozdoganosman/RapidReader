import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/book_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every bundled chapter with its series cover', () async {
    final books = await BookService.loadBooks();

    expect(books, hasLength(162));

    final attc = books.where((b) => b.seriesName == 'ATTC').toList();
    expect(attc, hasLength(45));
    expect(attc.every((b) => b.coverAsset == 'assets/books/ATTC.jpg'), isTrue);

    final donusum = books.where((b) => b.seriesName == 'Donusum').toList();
    expect(donusum, hasLength(3));
    expect(donusum.every((b) => b.coverAsset == 'assets/books/Donusum.jpg'), isTrue);

    // Covers are referenced by path; nothing is decoded into memory
    expect(books.every((b) => b.imageBase64 == null), isTrue);
  });

  test('bundled covers are small', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final covers = manifest.listAssets().where((a) => a.startsWith('assets/books/') && !a.endsWith('.txt'));

    expect(covers, isNotEmpty);
    for (final cover in covers) {
      final data = await rootBundle.load(cover);
      expect(data.lengthInBytes, lessThan(300 * 1024), reason: cover);
    }
  });

  test('word counts are computed once and stay the same', () async {
    final book = (await BookService.loadBooks()).first;
    expect(book.wordCount, greaterThan(0));
    expect(book.wordCount, book.wordCount);
  });
}
