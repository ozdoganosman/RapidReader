/// Text Parser for RSVP display
///
/// Tokenizes text into words with proper handling of:
/// - Turkish apostrophes (') - keeps words together
/// - Hyphens (-) - keeps words together
/// - Slashes (/) - splits words
/// - Parentheses, brackets, quotes - stay attached to the word
/// - Standalone punctuation - attached to the neighbouring word
/// - URLs and emails - single tokens
library;

import '../models/word_token.dart';
import 'timing_calculator.dart';

/// Parser for converting raw text into RSVP tokens
class TextParser {
  /// Regex patterns for special tokens that should not be split
  static final _urlPattern = RegExp(r'https?://\S+|www\.\S+');
  static final _emailPattern = RegExp(r'\S+@\S+\.\S+');

  /// A token made of punctuation only, e.g. a quote or dash between spaces
  static final _punctuationOnly = RegExp(r'^\p{P}+$', unicode: true);

  /// Opening brackets and quotes: ( [ { “ ‘ « „
  static final _openingPunctuation = RegExp(r'^[\p{Ps}\p{Pi}]+$', unicode: true);

  /// Dashes: - – —
  static final _dashPunctuation = RegExp(r'^\p{Pd}+$', unicode: true);

  /// Parse text into a list of word tokens
  ///
  /// [text] - Raw text to parse
  /// [chunkSize] - Number of words per chunk (1 = single words)
  static List<WordToken> parse(String text, {int chunkSize = 1}) {
    final tokens = <WordToken>[];

    // Normalize line endings
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Split into paragraphs
    final paragraphs = normalized.split(RegExp(r'\n\s*\n'));

    int globalIndex = 0;
    int sentenceCount = 0;

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final paragraph = paragraphs[pIdx].trim();
      if (paragraph.isEmpty) continue;

      // Tokenize paragraph
      final paragraphTokens = _tokenizeParagraph(paragraph);

      for (int wIdx = 0; wIdx < paragraphTokens.length; wIdx++) {
        final word = paragraphTokens[wIdx];
        if (word.isEmpty) continue;

        final isLastInParagraph = wIdx == paragraphTokens.length - 1;
        final hasSentenceEnd = _endsWithSentencePunct(word);

        if (hasSentenceEnd) sentenceCount++;

        tokens.add(WordToken(
          word: word,
          index: globalIndex,
          hasSentenceEndPunctuation: hasSentenceEnd,
          hasMidSentencePunctuation: _endsWithMidPunct(word),
          isParagraphEnd: isLastInParagraph,
          sentenceNumber: sentenceCount,
          isUrl: _isUrl(word),
        ));

        globalIndex++;
      }
    }

    // Apply chunking if requested
    if (chunkSize > 1) {
      return _applyChunking(tokens, chunkSize);
    }

    return tokens;
  }

  /// Tokenize a single paragraph into words
  static List<String> _tokenizeParagraph(String paragraph) {
    final tokens = <String>[];

    // First, protect URLs and emails by replacing them temporarily
    final protected = <String, String>{};
    int placeholderIdx = 0;

    String processed = paragraph;

    // Protect URLs
    for (final match in _urlPattern.allMatches(paragraph)) {
      final placeholder = '\x00URL$placeholderIdx\x00';
      protected[placeholder] = match.group(0)!;
      processed = processed.replaceFirst(match.group(0)!, placeholder);
      placeholderIdx++;
    }

    // Protect emails
    for (final match in _emailPattern.allMatches(processed)) {
      if (!match.group(0)!.startsWith('\x00')) {
        final placeholder = '\x00EMAIL$placeholderIdx\x00';
        protected[placeholder] = match.group(0)!;
        processed = processed.replaceFirst(match.group(0)!, placeholder);
        placeholderIdx++;
      }
    }

    // Split by whitespace
    final words = processed.split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.isEmpty) continue;

      // Restore protected tokens
      if (word.contains('\x00')) {
        String restored = word;
        for (final entry in protected.entries) {
          restored = restored.replaceAll(entry.key, entry.value);
        }
        tokens.add(restored);
        continue;
      }

      // Process word for special characters
      tokens.addAll(_processWord(word));
    }

    return _attachPunctuation(tokens);
  }

  /// Split a word at slashes and backslashes
  ///
  /// Everything else (apostrophes, hyphens, quotes, brackets, punctuation)
  /// stays attached to the word.
  static List<String> _processWord(String word) {
    return word.split(RegExp(r'[/\\]')).where((part) => part.isNotEmpty).toList();
  }

  /// Attach standalone punctuation to a neighbouring word
  ///
  /// A quote, bracket or dash surrounded by spaces would otherwise be shown
  /// as a word of its own. Opening quotes/brackets go to the next word,
  /// everything else to the previous one; dashes keep their space.
  /// Straight double quotes alternate between opening and closing.
  static List<String> _attachPunctuation(List<String> words) {
    final result = <String>[];
    var prefix = '';
    var doubleQuotes = 0;

    for (final word in words) {
      if (!_punctuationOnly.hasMatch(word)) {
        result.add('$prefix$word');
        prefix = '';
        doubleQuotes += '"'.allMatches(word).length;
        continue;
      }

      final bool opening;
      if (word == '"') {
        opening = doubleQuotes.isEven;
        doubleQuotes++;
      } else {
        opening = _openingPunctuation.hasMatch(word);
      }
      final isDash = _dashPunctuation.hasMatch(word);

      if (opening || result.isEmpty) {
        prefix += isDash ? '$word ' : word;
      } else {
        result[result.length - 1] += isDash ? ' $word' : word;
      }
    }

    // Opening punctuation at the very end has no following word
    if (prefix.isNotEmpty) {
      if (result.isEmpty) {
        result.add(prefix.trim());
      } else {
        result[result.length - 1] += ' ${prefix.trim()}';
      }
    }

    return result;
  }

  /// Apply chunking to group multiple words together
  ///
  /// A chunk never runs past the end of a sentence or paragraph, so the
  /// sentence and paragraph pauses stay where they belong. URLs are shown
  /// on their own.
  static List<WordToken> _applyChunking(List<WordToken> tokens, int chunkSize) {
    final chunked = <WordToken>[];
    var chunk = <WordToken>[];

    void flush() {
      if (chunk.isEmpty) return;

      // Inherit metadata from the last token of the chunk
      final last = chunk.last;
      chunked.add(WordToken(
        word: chunk.map((t) => t.word).join(' '),
        index: chunked.length,
        hasSentenceEndPunctuation: last.hasSentenceEndPunctuation,
        hasMidSentencePunctuation: last.hasMidSentencePunctuation,
        isParagraphEnd: last.isParagraphEnd,
        sentenceNumber: last.sentenceNumber,
        isChunk: chunk.length > 1,
        chunkSize: chunk.length,
        isUrl: chunk.length == 1 && last.isUrl,
      ));
      chunk = [];
    }

    for (final token in tokens) {
      if (token.isUrl) {
        flush();
        chunk.add(token);
        flush();
        continue;
      }

      chunk.add(token);
      if (chunk.length == chunkSize || token.hasSentenceEndPunctuation || token.isParagraphEnd) {
        flush();
      }
    }
    flush();

    return chunked;
  }

  /// Check if string is just punctuation
  static bool _isPunctuation(String s) => _punctuationOnly.hasMatch(s);

  /// Check if word ends with sentence punctuation (also before a closing
  /// quote or bracket, as in 'dedi."')
  static bool _endsWithSentencePunct(String word) {
    final type = TimingCalculator.detectPunctuation(word);
    return type == PunctuationType.sentenceEnd || type == PunctuationType.ellipsis;
  }

  /// Check if word ends with mid-sentence punctuation
  static bool _endsWithMidPunct(String word) {
    return TimingCalculator.detectPunctuation(word) == PunctuationType.midSentence;
  }

  /// Check if word is a URL or email
  static bool _isUrl(String word) {
    return _urlPattern.hasMatch(word) || _emailPattern.hasMatch(word);
  }

  /// Get statistics about parsed text
  static TextStats getStats(List<WordToken> tokens) {
    int wordCount = 0;
    int sentenceCount = 0;
    int paragraphCount = 0;

    for (final token in tokens) {
      // Don't count standalone punctuation
      if (token.word.length > 1 || !_isPunctuation(token.word)) {
        wordCount++;
      }
      if (token.hasSentenceEndPunctuation) sentenceCount++;
      if (token.isParagraphEnd) paragraphCount++;
    }

    return TextStats(
      wordCount: wordCount,
      sentenceCount: sentenceCount,
      paragraphCount: paragraphCount,
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
