/// Custom Book Service
///
/// Handles saving and loading user-created books to local storage.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';

/// Service for managing custom user-created books
///
/// Books are kept in a Hive box (IndexedDB on web, a file on mobile), one
/// entry per book, so saving one book does not rewrite the others and
/// large texts fit (browser preferences storage is limited to about 5 MB).
/// Books saved by older versions in shared_preferences are moved over once.
class CustomBookService {
  static const _boxName = 'custom_books';

  /// shared_preferences key used by older versions
  static const _legacyKey = 'custom_books';

  static const _uuid = Uuid();

  /// Prepares Hive's storage location; replaced in tests
  @visibleForTesting
  static Future<void> Function() initStorage = Hive.initFlutter;

  static Future<Box<String>>? _box;

  static Future<Box<String>> _openBox() => _box ??= () async {
        try {
          await initStorage();
          final box = await Hive.openBox<String>(_boxName);
          await _moveLegacyBooks(box);
          return box;
        } catch (_) {
          _box = null; // try again next time
          rethrow;
        }
      }();

  /// Forget the opened box (tests)
  @visibleForTesting
  static Future<void> reset() async {
    final box = _box;
    _box = null;
    if (box != null) await (await box).close();
  }

  static Future<void> _moveLegacyBooks(Box<String> box) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_legacyKey);
    if (jsonString == null) return;

    if (jsonString.isNotEmpty) {
      final List<dynamic> jsonList = json.decode(jsonString);
      // add() keys are increasing integers, so the order is kept
      for (final item in jsonList) {
        await box.add(json.encode(item));
      }
    }
    await prefs.remove(_legacyKey);
  }

  /// Load all custom books from local storage
  static Future<List<Book>> loadCustomBooks() async {
    try {
      final box = await _openBox();
      return [
        for (final value in box.values) Book.fromJson(json.decode(value) as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('CustomBookService error: $e');
      return [];
    }
  }

  /// Save a new custom book
  static Future<Book> saveCustomBook({
    required String title,
    required String content,
    String? author,
    String? imageBase64,
  }) async {
    final newBook = Book(
      id: 'custom_${_uuid.v4()}',
      title: title,
      author: author ?? 'Kullanıcı',
      category: 'Özel',
      coverColor: _generateRandomColor(),
      content: content,
      imageBase64: imageBase64,
    );

    final box = await _openBox();
    await box.add(json.encode(newBook.toJson()));

    return newBook;
  }

  /// Delete a custom book by ID
  static Future<void> deleteCustomBook(String id) async {
    final box = await _openBox();
    final key = _keyOf(box, id);
    if (key != null) await box.delete(key);
  }

  /// Update an existing custom book
  static Future<void> updateCustomBook(Book book) async {
    final box = await _openBox();
    final key = _keyOf(box, book.id);
    if (key != null) await box.put(key, json.encode(book.toJson()));
  }

  static dynamic _keyOf(Box<String> box, String id) {
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null && (json.decode(value) as Map<String, dynamic>)['id'] == id) return key;
    }
    return null;
  }

  /// Generate a random cover color
  static String _generateRandomColor() {
    final colors = [
      '#FF5722', '#2196F3', '#4CAF50', '#9C27B0',
      '#E91E63', '#3F51B5', '#FF9800', '#795548',
      '#00BCD4', '#8BC34A', '#673AB7', '#F44336',
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }
}
