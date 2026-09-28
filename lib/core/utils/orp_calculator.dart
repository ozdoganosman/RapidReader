/// ORP (Optimal Recognition Point) Calculator
///
/// Calculates the optimal focus point for each word in RSVP display.
/// Supports Turkish characters and handles apostrophes correctly.
library;

/// Result of splitting a word for ORP display
class ORPWordParts {
  /// Characters before the ORP point
  final String before;

  /// The ORP character (to be highlighted)
  final String orp;

  /// Characters after the ORP point
  final String after;

  const ORPWordParts({
    required this.before,
    required this.orp,
    required this.after,
  });

  @override
  String toString() => '$before[$orp]$after';
}

/// Calculator for Optimal Recognition Point
class ORPCalculator {
  /// Characters that don't count toward effective word length
  /// but should stay attached to the word
  /// Includes: apostrophe ('), right single quote, hyphen
  static const _ignoredInLength = {
    "'", // apostrophe
    "\u2019", // right single quote
    "-", // hyphen
    " ", // space between words of a chunk
  };

  /// Leading punctuation to strip before ORP calculation
  static const _leadingPunctuation = {
    '"', // double quote
    "'", // single quote
    '(', '[', '{',
    '\u00AB', // left guillemet
    '\u201C', // left double quote
    '\u201E', // low double quote
    '\u2018', // left single quote
    '\u2014', '\u2013', ' ', // attached dialogue dash: "— Merhaba"
  };

  /// Trailing punctuation to strip before ORP calculation
  static const _trailingPunctuation = {
    '"', // double quote
    "'", // single quote
    ')', ']', '}',
    '\u00BB', // right guillemet
    '\u201D', // right double quote
    '\u2019', // right single quote
    '.', ',', '!', '?', ':', ';',
    '\u2026', // ellipsis
    '\u2014', '\u2013', ' ', // attached dash: "bir —"
  };

  /// Calculate ORP index based on effective word length
  ///
  /// Algorithm:
  /// - 1 character: index 0
  /// - 2-5 characters: index 1
  /// - 6-9 characters: index 2
  /// - 10-13 characters: index 3
  /// - 14+ characters: index 4
  static int calculateORPIndex(int effectiveLength) {
    if (effectiveLength <= 1) return 0;
    if (effectiveLength <= 5) return 1;
    if (effectiveLength <= 9) return 2;
    if (effectiveLength <= 13) return 3;
    return 4;
  }

  /// Get effective length of a word (excluding apostrophes and hyphens)
  ///
  /// Examples:
  /// - "Turkiye'nin" -> 10 (apostrophe not counted)
  /// - "e-posta" -> 6 (hyphen not counted)
  /// - "covid-19" -> 7
  static int getEffectiveLength(String word) {
    final cleaned = _getCleanWord(word);
    int length = 0;
    for (final char in cleaned.runes) {
      final c = String.fromCharCode(char);
      if (!_ignoredInLength.contains(c)) {
        length++;
      }
    }
    return length;
  }

  /// Remove leading and trailing punctuation from a word
  static String _getCleanWord(String word) {
    if (word.isEmpty) return word;

    int start = 0;
    int end = word.length;

    // Remove leading punctuation
    while (start < end && _leadingPunctuation.contains(word[start])) {
      start++;
    }

    // Remove trailing punctuation
    while (end > start && _trailingPunctuation.contains(word[end - 1])) {
      end--;
    }

    return word.substring(start, end);
  }

  /// Get the actual character index for ORP in the original word
  ///
  /// Leading/trailing punctuation is skipped, and the ORP always lands on a
  /// letter that counts toward the length - never on an apostrophe, hyphen
  /// or space ("O'na" -> "n", not "'").
  static int getActualORPIndex(String word) {
    if (word.isEmpty) return 0;

    // Bounds of the word without leading and trailing punctuation
    var start = 0;
    var end = word.length;
    while (start < end && _leadingPunctuation.contains(word[start])) {
      start++;
    }
    while (end > start && _trailingPunctuation.contains(word[end - 1])) {
      end--;
    }
    if (start == end) return 0;

    final orpIndex = calculateORPIndex(getEffectiveLength(word));

    // Find the orpIndex-th counted character
    var counted = 0;
    var lastCounted = start;
    for (var i = start; i < end; i++) {
      if (_ignoredInLength.contains(word[i])) continue;
      if (counted == orpIndex) return i;
      lastCounted = i;
      counted++;
    }

    return lastCounted;
  }

  /// Split word into three parts for ORP display
  ///
  /// The ORP character is centered, with before/after parts on sides.
  ///
  /// Examples:
  /// - "kitap" -> before: "k", orp: "i", after: "tap"
  /// - "Turkiye'nin" -> before: "Tu", orp: "r", after: "kiye'nin"
  static ORPWordParts splitForDisplay(String word) {
    if (word.isEmpty) {
      return const ORPWordParts(before: '', orp: '', after: '');
    }

    final orpIndex = getActualORPIndex(word);

    if (orpIndex >= word.length) {
      return ORPWordParts(before: word, orp: '', after: '');
    }

    return ORPWordParts(
      before: word.substring(0, orpIndex),
      orp: word[orpIndex],
      after: orpIndex + 1 < word.length ? word.substring(orpIndex + 1) : '',
    );
  }
}
