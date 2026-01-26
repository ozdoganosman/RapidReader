/// Text Parser for RSVP display
///
/// Simple tokenizer that splits text by whitespace only.
/// Keeps all characters intact - no filtering or transformation.
library;

import '../models/word_token.dart';

/// Parser for converting raw text into RSVP tokens
class TextParser {
  /// Parse text into a list of word tokens
  ///
  /// Simple approach: split by whitespace, keep everything else intact
  static List<WordToken> parse(String text, {int chunkSize = 1}) {
    if (text.isEmpty) return [];

    final tokens = <WordToken>[];

    // Split by any whitespace
    final words = text.split(RegExp(r'\s+'));

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final hasSentenceEnd = _endsWithSentencePunct(word);
      final hasMidPunct = _endsWithMidPunct(word);

      tokens.add(WordToken(
        word: word,
        index: tokens.length,
        hasSentenceEndPunctuation: hasSentenceEnd,
        hasMidSentencePunctuation: hasMidPunct,
        isParagraphEnd: false,
        sentenceNumber: 0,
        isUrl: false,
      ));
    }

    // Apply chunking if requested
    if (chunkSize > 1) {
      return _applyChunking(tokens, chunkSize);
    }

    return tokens;
  }

  /// Check if word ends with sentence punctuation
  static bool _endsWithSentencePunct(String word) {
    if (word.isEmpty) return false;
    final last = word[word.length - 1];
    return '.!?'.contains(last);
  }

  /// Check if word ends with mid-sentence punctuation
  static bool _endsWithMidPunct(String word) {
    if (word.isEmpty) return false;
    final last = word[word.length - 1];
    return ',;:'.contains(last);
  }

  /// Apply chunking to group multiple words together
  static List<WordToken> _applyChunking(List<WordToken> tokens, int chunkSize) {
    final chunked = <WordToken>[];

    for (int i = 0; i < tokens.length; i += chunkSize) {
      final chunkEnd = (i + chunkSize).clamp(0, tokens.length);
      final chunk = tokens.sublist(i, chunkEnd);

      // Combine words in chunk
      final combinedWord = chunk.map((t) => t.word).join(' ');
      final lastToken = chunk.last;

      chunked.add(WordToken(
        word: combinedWord,
        index: chunked.length,
        hasSentenceEndPunctuation: lastToken.hasSentenceEndPunctuation,
        hasMidSentencePunctuation: lastToken.hasMidSentencePunctuation,
        isParagraphEnd: lastToken.isParagraphEnd,
        sentenceNumber: lastToken.sentenceNumber,
        isChunk: true,
        chunkSize: chunk.length,
        isUrl: false,
      ));
    }

    return chunked;
  }

  /// Get statistics about parsed text
  static TextStats getStats(List<WordToken> tokens) {
    return TextStats(
      wordCount: tokens.length,
      sentenceCount: tokens.where((t) => t.hasSentenceEndPunctuation).length,
      paragraphCount: 1,
      tokenCount: tokens.length,
    );
  }
}

/// Statistics about parsed text
class TextStats {
  final int wordCount;
  final int sentenceCount;
  final int paragraphCount;
  final int tokenCount;

  const TextStats({
    required this.wordCount,
    required this.sentenceCount,
    required this.paragraphCount,
    required this.tokenCount,
  });

  /// Estimated reading time at given WPM
  Duration estimatedReadingTime(int wpm) {
    final minutes = wordCount / wpm;
    return Duration(seconds: (minutes * 60).round());
  }
}
