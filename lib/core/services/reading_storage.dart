/// Reading Storage Service
///
/// Saves the reader settings and the reading position of every book on the
/// device (shared_preferences), so they survive an app restart.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/rsvp_settings.dart';

/// Saved reading position of a book
class ReadingProgress {
  /// Index of the current word; equal to [total] when the book is finished
  final int index;

  /// Number of words (tokens) when the position was saved
  final int total;

  const ReadingProgress({required this.index, required this.total});

  /// Whether the book was read to the end
  bool get isComplete => total > 0 && index >= total;
}

/// Service for storing settings and reading positions
class ReadingStorage {
  static const _settingsKey = 'rsvp_settings';
  static const _progressPrefix = 'reading_progress_';

  /// Saved settings, or defaults when nothing was saved yet
  static Future<RSVPSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString == null) return const RSVPSettings();
      return RSVPSettings.fromMap(json.decode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      return const RSVPSettings();
    }
  }

  /// Save settings
  static Future<void> saveSettings(RSVPSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toMap()));
  }

  /// Saved reading position of a book, if any
  static Future<ReadingProgress?> loadProgress(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList('$_progressPrefix$bookId');
      if (values == null || values.length != 2) return null;
      return ReadingProgress(index: int.parse(values[0]), total: int.parse(values[1]));
    } catch (_) {
      return null;
    }
  }

  /// Save the reading position of a book
  static Future<void> saveProgress(String bookId, ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_progressPrefix$bookId',
      ['${progress.index}', '${progress.total}'],
    );
  }

  static const _lastReadKey = 'last_read';

  /// Remember the book opened last and how it was read (a reading mode's
  /// name), for "Devam Et"
  static Future<void> saveLastRead(String bookId, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastReadKey, [bookId, mode]);
  }

  /// The book opened last and its reading mode, if any
  static Future<({String bookId, String mode})?> loadLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_lastReadKey);
      if (values == null || values.length != 2) return null;
      return (bookId: values[0], mode: values[1]);
    } catch (_) {
      return null;
    }
  }
}
