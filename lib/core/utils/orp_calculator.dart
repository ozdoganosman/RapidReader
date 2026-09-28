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
  /// For chunks (multi-word), calculates ORP on the middle word
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

  /// Split a chunk (multi-word text) for ORP display
  /// ORP is calculated on the middle word of the chunk
  static ORPWordParts _splitChunkForDisplay(String text, List<String> words) {
    // Find the target word index (middle word, or slightly right of center)
    // For 2 words: use word index 1 (second word)
    // For 3 words: use word index 1 (middle word)
    final targetWordIndex = words.length ~/ 2;
    final targetWord = words[targetWordIndex];

    // Calculate ORP for the target word
    final safeWordOrpIndex = orpIndexOf(targetWord);

    // Build the before part: all words before target + beginning of target word
    final beforeWords = words.sublist(0, targetWordIndex);
    final beforePart = beforeWords.isNotEmpty
        ? '${beforeWords.join(' ')} ${targetWord.substring(0, safeWordOrpIndex)}'
        : targetWord.substring(0, safeWordOrpIndex);

    // The ORP character
    final orpChar = targetWord[safeWordOrpIndex];

    // Build the after part: rest of target word + all words after target
    final afterTargetWord = safeWordOrpIndex + 1 < targetWord.length
        ? targetWord.substring(safeWordOrpIndex + 1)
        : '';
    final afterWords = words.sublist(targetWordIndex + 1);
    final afterPart = afterWords.isNotEmpty
        ? '$afterTargetWord ${afterWords.join(' ')}'
        : afterTargetWord;

    return ORPWordParts(
      before: beforePart,
      orp: orpChar,
      after: afterPart,
    );
  }

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
