import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rapid_reader/core/services/custom_book_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('custom_books');
    CustomBookService.initStorage = () async => Hive.init(dir.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await CustomBookService.reset();
    await dir.delete(recursive: true);
  });

  test('saves, lists in order and deletes books', () async {
    final first = await CustomBookService.saveCustomBook(title: 'Bir', content: 'bir iki');
    await CustomBookService.saveCustomBook(title: 'İki', content: 'üç dört', author: 'Yazar');

    var books = await CustomBookService.loadCustomBooks();
    expect(books.map((b) => b.title), ['Bir', 'İki']);
    expect(books.last.author, 'Yazar');

    await CustomBookService.deleteCustomBook(first.id);
    books = await CustomBookService.loadCustomBooks();
    expect(books.map((b) => b.title), ['İki']);
  });

  test('keeps a text larger than the 5 MB browser preferences limit', () async {
    final big = 'kelime ' * 1000000; // 7 MB
    await CustomBookService.saveCustomBook(title: 'Büyük', content: big);

    await CustomBookService.reset(); // read back from disk
    final books = await CustomBookService.loadCustomBooks();
    expect(books.single.content.length, big.length);
  });

  test('moves books saved by older versions out of shared_preferences', () async {
    SharedPreferences.setMockInitialValues({
      'custom_books': json.encode([
        {'id': 'custom_a', 'title': 'Eski 1', 'author': 'A', 'category': 'Özel', 'coverColor': '#FF5722', 'content': 'x'},
        {'id': 'custom_b', 'title': 'Eski 2', 'author': 'B', 'category': 'Özel', 'coverColor': '#2196F3', 'content': 'y'},
      ]),
    });

    final books = await CustomBookService.loadCustomBooks();
    expect(books.map((b) => b.id), ['custom_a', 'custom_b']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('custom_books'), isNull);

    // Not moved twice
    await CustomBookService.reset();
    expect(await CustomBookService.loadCustomBooks(), hasLength(2));
  });
}
