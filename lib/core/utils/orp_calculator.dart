/// ORP (Optimal Recognition Point) Calculator
///
/// Calculates the optimal focus point for each word in RSVP display.
/// Simple approach: ORP is approximately 1/3 into the word. Punctuation
/// around the word and apostrophes/hyphens inside it are not counted, so
/// the ORP always lands on a letter (e.g. "O'na" -> "n").
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
  /// Punctuation skipped at the start of a word when placing the ORP
  static const _leadingPunctuation = {
    '"', "'", '(', '[', '{',
    '\u00AB', // «
    '\u201C', // “
    '\u201E', // „
    '\u2018', // ‘
    '\u2014', '\u2013', // — –
  };

  /// Punctuation skipped at the end of a word when placing the ORP
  static const _trailingPunctuation = {
    '"', "'", ')', ']', '}',
    '\u00BB', // »
    '\u201D', // ”
    '\u2019', // ’
    '.', ',', '!', '?', ':', ';',
    '\u2026', // …
    '\u2014', '\u2013', // — –
  };

  /// Characters inside a word that never become the ORP
  static const _ignoredInWord = {"'", '\u2019', '-'};

  /// Calculate ORP index based on word length
  ///
  /// Simple rule: ORP is about 1/3 into the word
  /// - 1-2 characters: index 0
  /// - 3-5 characters: index 1
  /// - 6-9 characters: index 2
  /// - 10-13 characters: index 3
  /// - 14+ characters: index 4
  static int calculateORPIndex(int length) {
    if (length <= 2) return 0;
    if (length <= 5) return 1;
    if (length <= 9) return 2;
    if (length <= 13) return 3;
    return 4;
  }

  /// Split word into three parts for ORP display
  ///
  /// Returns before, orp character, and after parts
  /// For chunks (multi-word), the ORP is near the middle of the chunk
  static ORPWordParts splitForDisplay(String text) {
    if (text.isEmpty) {
      return const ORPWordParts(before: '', orp: '', after: '');
    }

    if (text.length == 1) {
      return ORPWordParts(before: '', orp: text, after: '');
    }

    // Check if this is a chunk (contains spaces)
    final words = text.split(' ');
    if (words.length > 1) {
      // For chunks, find the middle word and calculate ORP on it
      return _splitChunkForDisplay(text, words);
    }

    // Single word - use standard ORP calculation
    final safeIndex = orpIndexOf(text);

    return ORPWordParts(
      before: text.substring(0, safeIndex),
      orp: text[safeIndex],
      after: safeIndex + 1 < text.length ? text.substring(safeIndex + 1) : '',
    );
  }

  /// Split a chunk (several words) for ORP display
  ///
  /// The ORP is the letter nearest to the middle of the chunk (but not the
  /// first letter of a later word), so the chunk is centered and the eye
  /// rests between its words. A token that is one
  /// word with a spaced dash ("kelime —") keeps the word's own ORP.
  static ORPWordParts _splitChunkForDisplay(String text, List<String> words) {
    final int index;
    final realWords = words.where(hasLetter).length;
    if (realWords <= 1) {
      var offset = 0;
      for (final word in words) {
        if (hasLetter(word) || realWords == 0) break;
        offset += word.length + 1;
      }
      final word = text.substring(offset).split(' ').first;
      index = offset + orpIndexOf(word);
    } else {
      final middle = (text.length - 1) / 2;
      var best = 0;
      for (var i = 0; i < text.length; i++) {
        // Not the first letter of a later word: the space before it would
        // end the right-aligned part and not be drawn
        if (!_isLetter(text[i]) || (i > 0 && text[i - 1] == ' ')) continue;
        if (!_isLetter(text[best]) || (i - middle).abs() < (best - middle).abs()) best = i;
      }
      index = best;
    }

    return ORPWordParts(
      before: text.substring(0, index),
      orp: text[index],
      after: index + 1 < text.length ? text.substring(index + 1) : '',
    );
  }

  static final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static bool _isLetter(String char) => _letterOrDigit.hasMatch(char);

  /// Whether [word] has a letter or digit (is not only punctuation)
  static bool hasLetter(String word) => _letterOrDigit.hasMatch(word);

  /// Index of the ORP character in a single [word]
  ///
  /// Counts only the letters between leading and trailing punctuation,
  /// skipping apostrophes and hyphens, and returns the position of the
  /// [calculateORPIndex]-th of them.
  static int orpIndexOf(String word) {
    if (word.isEmpty) return 0;

    var start = 0;
    var end = word.length;
    while (start < end && _leadingPunctuation.contains(word[start])) {
      start++;
    }
    while (end > start && _trailingPunctuation.contains(word[end - 1])) {
      end--;
    }

    final letters = <int>[
      for (var i = start; i < end; i++)
        if (!_ignoredInWord.contains(word[i])) i,
    ];
    if (letters.isEmpty) return start < word.length ? start : 0;

    final index = calculateORPIndex(letters.length).clamp(0, letters.length - 1);
    return letters[index];
  }

  /// Get effective length (same as actual length in simplified version)
  static int getEffectiveLength(String word) {
    return word.length;
  }
}
