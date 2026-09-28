/// Text Cleaner Service
///
/// Cleans text extracted from PDFs and plain-text files by removing:
/// - Page numbers
/// - Copyright/ISBN/publisher lines
/// - Footnote marker lines
/// - Excessive whitespace
///
/// Only whole, short lines that look like metadata are removed. Words such as
/// "baskı" or "publishers" inside normal prose are never touched.
library;

/// Service for cleaning and preprocessing text before RSVP reading
class TextCleaner {
  /// Lines longer than this are treated as prose and never removed as metadata
  static const _maxMetadataLineLength = 100;

  // Whole-line noise patterns (matched against the trimmed line)
  static final _pageNumberPattern = RegExp(r'^\d{1,4}$');
  static final _pageLabelPattern = RegExp(
    r'^(?:page|sayfa|s\.)\s*\d+$',
    caseSensitive: false,
  );
  static final _footnotePattern = RegExp(r'^[\[\(]\d+[\]\)]$');

  // Inline ISBN numbers are always metadata, even inside a longer line
  static final _isbnPattern = RegExp(
    r'ISBN[\s\-:]*[\d\-X]{10,}',
    caseSensitive: false,
  );

  /// Metadata line patterns, matched against the folded (lowercase,
  /// dotless/dotted i normalized to "i") trimmed line.
  static final _metadataPatterns = [
    // © 2020 ..., (c) 2020 ..., Copyright ..., Telif hakkı ...
    RegExp(r'^(?:©|\(c\)|copyright\b|telif hakk)'),
    // All rights reserved / Tüm hakları saklıdır / Her hakkı saklıdır
    RegExp(r'all rights reserved|(?:hakki|haklari) saklidir'),
    // ISBN 978-...
    RegExp(r'^isbn\b'),
    // Published by X / First published 1998 / First edition 2001
    RegExp(r'^(?:published by|first published|first edition)\b'),
    // Yayınevi: X / Publisher: X / 1. Baskı: Mart 2020 / Basım: X Matbaası
    RegExp(r'^(?:\d+\.\s*)?(?:publisher|yayinevi|yayinci|baski|basim)\s*:'),
    // 1. Baskı, 2019 / Birinci Baskı Mart 2020 / İlk Basım 2018
    RegExp(
      r'^(?:\d+\.\s*|birinci\s+|ilk\s+)?(?:baski|basim)\s*,?\s*(?:\S+\s+)?\d{4}\.?$',
    ),
  ];

  static final _excessiveNewlinesPattern = RegExp(r'\n\s*\n\s*\n+');
  static final _trailingWhitespacePattern = RegExp(r'[ \t]+$', multiLine: true);

  // Patterns indicating table of contents or metadata sections
  static final _tocPatterns = [
    RegExp(r'^İÇİNDEKİLER\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^TABLE OF CONTENTS\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^CONTENTS\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^İçindekiler\s*$', multiLine: true),
  ];

  static final _skipSectionPatterns = [
    RegExp(r'^ÖNSÖZ\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^FOREWORD\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^PREFACE\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^GİRİŞ\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^INTRODUCTION\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^ABOUT THE AUTHOR\s*$', multiLine: true, caseSensitive: false),
    RegExp(r'^YAZAR HAKKINDA\s*$', multiLine: true, caseSensitive: false),
  ];

  /// Main cleaning function - removes all common unwanted content
  static String clean(String text) {
    if (text.isEmpty) return text;

    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final kept = <String>[];

    for (final line in lines) {
      if (_isNoiseLine(line.trim())) continue;
      kept.add(line.replaceAll(_isbnPattern, ''));
    }

    return _normalizeWhitespace(kept.join('\n')).trim();
  }

  /// Whether a trimmed line is a page number, footnote marker or metadata
  static bool _isNoiseLine(String trimmed) {
    if (trimmed.isEmpty) return false;

    if (_pageNumberPattern.hasMatch(trimmed) ||
        _pageLabelPattern.hasMatch(trimmed) ||
        _footnotePattern.hasMatch(trimmed)) {
      return true;
    }

    // Long lines are prose, even if they mention "baskı" or "copyright"
    if (trimmed.length > _maxMetadataLineLength) return false;

    final folded = _fold(trimmed);
    return _metadataPatterns.any((p) => p.hasMatch(folded));
  }

  /// Lowercase with Turkish I/İ/ı/i all folded to "i", so patterns match
  /// both "BASKI" and "baskı" as well as English words like "PUBLISHED".
  static String _fold(String text) {
    return text.replaceAll(RegExp('[Iİı]'), 'i').toLowerCase();
  }

  /// Normalize whitespace - reduce multiple blank lines to a single blank line
  static String _normalizeWhitespace(String text) {
    var result = text;

    // Remove trailing whitespace from lines
    result = result.replaceAll(_trailingWhitespacePattern, '');

    // Reduce 3+ consecutive newlines to 2
    result = result.replaceAll(_excessiveNewlinesPattern, '\n\n');

    return result;
  }

  /// Detect where actual content starts (skip TOC, foreword, etc.)
  /// Returns the character index where content likely begins
  static int detectContentStart(String text) {
    final lines = text.split('\n');
    var tocEndIndex = 0;
    var inTocSection = false;
    var charCount = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Check if we're entering a TOC section
      if (_tocPatterns.any((p) => p.hasMatch(trimmed))) {
        inTocSection = true;
        tocEndIndex = charCount;
        charCount += line.length + 1; // +1 for newline
        continue;
      }

      // Check for skip sections (foreword, etc.)
      if (_skipSectionPatterns.any((p) => p.hasMatch(trimmed))) {
        tocEndIndex = charCount;
        charCount += line.length + 1;
        continue;
      }

      // If in TOC section, look for end indicators
      if (inTocSection) {
        // TOC entries usually have dots or numbers at the end
        if (RegExp(r'\.{2,}\s*\d+\s*$').hasMatch(trimmed) ||
            RegExp(r'\s+\d+\s*$').hasMatch(trimmed)) {
          tocEndIndex = charCount + line.length + 1;
          charCount += line.length + 1;
          continue;
        }

        // Empty line might indicate end of TOC
        if (trimmed.isEmpty) {
          charCount += line.length + 1;
          continue;
        }

        // Substantial text after TOC might be content start
        if (trimmed.length > 50) {
          inTocSection = false;
        }
      }

      // After TOC section, look for first substantial paragraph
      if (!inTocSection && i > 10) {
        // Found substantial text - this is likely content
        if (trimmed.length > 100 && trimmed.split(' ').length > 15) {
          return tocEndIndex > 0 ? tocEndIndex : 0;
        }
      }

      charCount += line.length + 1;
    }

    return tocEndIndex > 0 ? tocEndIndex : 0;
  }

  /// Get a preview of the cleaned text (first N characters)
  static String getPreview(String text, {int maxLength = 500}) {
    final cleaned = clean(text);
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength)}...';
  }

  /// Get statistics about the cleaning process
  static TextCleaningStats getStats(String original, String cleaned) {
    final originalWords = _countWords(original);
    final cleanedWords = _countWords(cleaned);

    return TextCleaningStats(
      originalLength: original.length,
      cleanedLength: cleaned.length,
      originalWords: originalWords,
      cleanedWords: cleanedWords,
      removedCharacters: original.length - cleaned.length,
      removedWords: originalWords - cleanedWords,
    );
  }

  static int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

/// Statistics about text cleaning process
class TextCleaningStats {
  final int originalLength;
  final int cleanedLength;
  final int originalWords;
  final int cleanedWords;
  final int removedCharacters;
  final int removedWords;

  const TextCleaningStats({
    required this.originalLength,
    required this.cleanedLength,
    required this.originalWords,
    required this.cleanedWords,
    required this.removedCharacters,
    required this.removedWords,
  });

  double get reductionPercentage =>
      originalLength > 0 ? (removedCharacters / originalLength) * 100 : 0;
}
