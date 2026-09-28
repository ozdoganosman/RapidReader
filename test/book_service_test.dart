import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/book.dart';
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

    final kuran = books.where((b) => b.seriesName == 'Kuran').toList();
    expect(kuran, hasLength(114));
    expect(kuran.every((b) => b.coverAsset == 'assets/books/Kuran.jpg'), isTrue);

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

  test('texts are loaded only when a book is opened', () async {
    final book = (await BookService.loadBooks()).firstWhere((b) => b.id == 'attc_2');

    expect(book.content, isEmpty);
    expect(book.title, 'Posta Arabası');
    expect(book.author, 'Charles Dickens');

    final content = await BookService.loadContent(book);
    expect(content, startsWith('Posta Arabası\nCharles Dickens\n'));
    // The index word count matches the text
    expect(book.wordCount, Book.countWords(content));
  });

  test('series have Turkish display names', () {
    expect(BookService.seriesDisplayName('ATTC'), 'İki Şehrin Hikâyesi');
    expect(BookService.seriesDisplayName('Donusum'), 'Dönüşüm');
    expect(BookService.seriesDisplayName('Kuran'), "Kur'an-ı Kerim");
    expect(BookService.seriesDisplayName('Yeni Seri'), 'Yeni Seri');
  });
}
