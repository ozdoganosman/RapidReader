/// Custom Book Service
///
/// Handles saving and loading user-created books to local storage.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';

/// Service for managing custom user-created books
class CustomBookService {
  static const String _storageKey = 'custom_books';
  static const _uuid = Uuid();

  /// Load all custom books from local storage
  static Future<List<Book>> loadCustomBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => Book.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
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
    final books = await loadCustomBooks();

    final newBook = Book(
      id: 'custom_${_uuid.v4()}',
      title: title,
      author: author ?? 'Kullanıcı',
      category: 'Özel',
      coverColor: _generateRandomColor(),
      content: content,
      imageBase64: imageBase64,
    );

    books.add(newBook);
    await _saveBooks(books);

    return newBook;
  }

  /// Delete a custom book by ID
  static Future<void> deleteCustomBook(String id) async {
    final books = await loadCustomBooks();
    books.removeWhere((book) => book.id == id);
    await _saveBooks(books);
  }

  /// Update an existing custom book
  static Future<void> updateCustomBook(Book book) async {
    final books = await loadCustomBooks();
    final index = books.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      books[index] = book;
      await _saveBooks(books);
    }
  }

  /// Save books list to local storage
  static Future<void> _saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = books.map((book) => book.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
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
