/// Text Cleaner Service
///
/// Automatically cleans extracted text from PDFs and other sources by removing:
/// - Page numbers
/// - Headers/footers
/// - Copyright/ISBN information
/// - Table of contents
/// - Excessive whitespace
library;

/// Service for cleaning and preprocessing text before RSVP reading
class TextCleaner {
  // Regex patterns for common unwanted content
  static final _pageNumberPattern = RegExp(r'^\s*\d{1,4}\s*$', multiLine: true);
  static final _isbnPattern = RegExp(
    r'ISBN[\s\-:]*[\d\-X]{10,}',
    caseSensitive: false,
  );
  static final _copyrightPattern = RegExp(
    r'[©®™].*?(?=\n|$)',
    caseSensitive: false,
  );
  static final _copyrightTextPattern = RegExp(
    r'(?:Copyright|Telif Hakkı|All Rights Reserved|Tüm Hakları Saklıdır).*?(?=\n|$)',
    caseSensitive: false,
  );
  static final _publisherPattern = RegExp(
    r'(?:Published by|Publisher|Yayınevi|Yayıncı|Basım|Baskı).*?(?=\n|$)',
    caseSensitive: false,
  );
  static final _footnotePattern = RegExp(
    r'^\s*[\[\(]\d+[\]\)]\s*$',
    multiLine: true,
  );
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

    var result = text;

    // Remove page numbers (lines containing only digits)
    result = _removePageNumbers(result);

    // Remove ISBN/copyright/publisher information
    result = _removeMetadata(result);

    // Remove footnote markers
    result = _removeFootnotes(result);

    // Normalize excessive whitespace
    result = _normalizeWhitespace(result);

    return result.trim();
  }

  /// Remove standalone page numbers
  static String _removePageNumbers(String text) {
    // Split into lines and filter out page number lines
    final lines = text.split('\n');
    final filteredLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip lines that are just numbers (page numbers)
      if (_pageNumberPattern.hasMatch(trimmed)) {
        continue;
      }

      // Skip lines that are just "Page X" or "Sayfa X"
      if (RegExp(r'^(?:Page|Sayfa|S\.)\s*\d+\s*$', caseSensitive: false)
          .hasMatch(trimmed)) {
        continue;
      }

      filteredLines.add(line);
    }

    return filteredLines.join('\n');
  }

  /// Remove ISBN, copyright, and publisher information
  static String _removeMetadata(String text) {
    var result = text;

    // Remove ISBN
    result = result.replaceAll(_isbnPattern, '');

    // Remove copyright symbols and text
    result = result.replaceAll(_copyrightPattern, '');
    result = result.replaceAll(_copyrightTextPattern, '');

    // Remove publisher info
    result = result.replaceAll(_publisherPattern, '');

    return result;
  }

  /// Remove footnote markers like [1], (2), etc.
  static String _removeFootnotes(String text) {
    return text.replaceAll(_footnotePattern, '');
  }

  /// Normalize whitespace - reduce multiple blank lines to maximum 2
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
