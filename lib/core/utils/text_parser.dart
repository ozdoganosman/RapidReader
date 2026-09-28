/// Text Parser for RSVP display
///
/// Simple tokenizer that splits text by whitespace and keeps every
/// character intact. Two small additions on top of the plain split:
/// - Punctuation standing alone between spaces (a quote, a dash, "?") is
///   attached to the neighbouring word instead of being shown as a word
///   of its own.
/// - Each line break ends a paragraph, so the reader pauses there.
library;

import '../models/word_token.dart';
import 'timing_calculator.dart';

/// Parser for converting raw text into RSVP tokens
class TextParser {
  /// A token made of punctuation only, e.g. a quote or dash between spaces
  static final _punctuationOnly = RegExp(r'^\p{P}+$', unicode: true);

  /// Opening brackets and quotes: ( [ { “ ‘ « „
  static final _openingPunctuation = RegExp(r'^[\p{Ps}\p{Pi}]+$', unicode: true);

  /// Dashes: - – —
  static final _dashPunctuation = RegExp(r'^\p{Pd}+$', unicode: true);

  /// Parse text into a list of word tokens
  ///
  /// Simple approach: split by whitespace, keep everything else intact
  static List<WordToken> parse(String text, {int chunkSize = 1}) {
    if (text.isEmpty) return [];

    final tokens = <WordToken>[];
    int sentenceCount = 0;

    // Every line is a paragraph (book files use one line per paragraph)
    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    for (final line in lines) {
      final words = _attachPunctuation(
        line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList(),
      );

      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final hasSentenceEnd =
            _endsWithSentencePunct(word) && !_isAbbreviation(word, i + 1 < words.length ? words[i + 1] : null);
        if (hasSentenceEnd) sentenceCount++;

        tokens.add(WordToken(
          word: word,
          index: tokens.length,
          hasSentenceEndPunctuation: hasSentenceEnd,
          hasMidSentencePunctuation: _endsWithMidPunct(word),
          isParagraphEnd: i == words.length - 1,
          sentenceNumber: sentenceCount,
          isUrl: false,
        ));
      }
    }

    // Apply chunking if requested
    if (chunkSize > 1) {
      return _applyChunking(tokens, chunkSize);
    }

    return tokens;
  }

  /// Attach standalone punctuation to a neighbouring word
  ///
  /// Opening quotes/brackets go to the next word, everything else to the
  /// previous one; dashes keep their space. Straight double quotes
  /// alternate between opening and closing.
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

  /// Check if word ends with sentence punctuation (also before a closing
  /// quote or bracket, as in 'dedi."')
  static bool _endsWithSentencePunct(String word) {
    final type = TimingCalculator.detectPunctuation(word);
    return type == PunctuationType.sentenceEnd || type == PunctuationType.ellipsis;
  }

  /// Titles written with a period ("Dr. Ahmet")
  static const _titles = {
    'Dr.', 'Prof.', 'Doç.', 'Yrd.', 'Av.', 'Op.', 'Uzm.', 'Sn.', 'Bkz.', //
    'Mr.', 'Mrs.', 'Ms.', 'St.', 'Mt.',
  };

  static final _lowercaseStart = RegExp(r'^[^\p{L}\p{N}]*\p{Ll}', unicode: true);

  /// Whether the period of [word] marks an abbreviation or ordinal rather
  /// than a sentence end: a title ("Dr. Ahmet"), or a single period before
  /// a word in lowercase ("19. yüzyılda", "vb. şeyler"), since a new
  /// sentence starts with a capital letter
  static bool _isAbbreviation(String word, String? next) {
    if (_titles.contains(word)) return true;
    if (!word.endsWith('.') || word.endsWith('..') || next == null) return false;
    return _lowercaseStart.hasMatch(next);
  }

  /// Check if word ends with mid-sentence punctuation
  static bool _endsWithMidPunct(String word) {
    return TimingCalculator.detectPunctuation(word) == PunctuationType.midSentence;
  }

  /// Apply chunking to group multiple words together
  ///
  /// A chunk never runs past the end of a sentence or paragraph, so the
  /// sentence and paragraph pauses stay where they belong. Groups follow
  /// the meaning a little: short words go with the word they belong to.
  static List<WordToken> _applyChunking(List<WordToken> tokens, int chunkSize) {
    final chunked = <WordToken>[];
    var chunk = <WordToken>[];

    void flush() {
      if (chunk.isEmpty) return;

      // Combine words in chunk, inheriting metadata from the last one
      final lastToken = chunk.last;
      chunked.add(WordToken(
        word: chunk.map((t) => t.word).join(' '),
        index: chunked.length,
        hasSentenceEndPunctuation: lastToken.hasSentenceEndPunctuation,
        hasMidSentencePunctuation: lastToken.hasMidSentencePunctuation,
        isParagraphEnd: lastToken.isParagraphEnd,
        sentenceNumber: lastToken.sentenceNumber,
        isChunk: chunk.length > 1,
        chunkSize: chunk.length,
        isUrl: false,
      ));
      chunk = [];
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      chunk.add(token);
      if (token.hasSentenceEndPunctuation || token.isParagraphEnd) {
        flush();
        continue;
      }
      if (chunk.length < chunkSize) continue;

      // Meaning groups: a little word that leads into the next one ("ve",
      // "bir", "bu") starts the next group instead of ending this one...
      if (chunk.length >= 2 && chunk.length == chunkSize && _leadsIn(chunk.last)) {
        final carried = chunk.removeLast();
        flush();
        chunk.add(carried);
        continue;
      }
      // ...and one that belongs to the word before it ("da", "ki", "gibi")
      // joins this group (one word over the size at most)
      final next = i + 1 < tokens.length ? tokens[i + 1] : null;
      if (chunk.length == chunkSize && next != null && _followsOn(next)) continue;
      flush();
    }
    flush();

    return chunked;
  }

  /// Short words read together with the word after them
  static const _leadingWords = {
    've', 'veya', 'ya', 'yahut', 'ile', 'bir', 'bu', 'şu', 'her', 'hiç', 'çok', 'en', 'daha', 'pek', //
    'ne', 'ama', 'fakat', 'ancak', 'hem', 'yani', 'the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', //
    'on', 'at', 'for', 'with', 'by', 'from',
  };

  /// Short words read together with the word before them
  static const _followingWords = {
    'da', 'de', 'ta', 'te', 'ki', 'mi', 'mı', 'mu', 'mü', 'gibi', 'için', 'kadar', 'göre', 'diye', //
    'bile', 'ise', 'dahi',
  };

  static final _trailingPunctuation = RegExp(r'[^\p{L}\p{N}]+$', unicode: true);

  /// A leading word without punctuation after it (a comma ends the thought)
  static bool _leadsIn(WordToken token) =>
      !token.hasMidSentencePunctuation && _leadingWords.contains(token.word.toLowerCase());

  static bool _followsOn(WordToken token) =>
      _followingWords.contains(token.word.replaceFirst(_trailingPunctuation, '').toLowerCase());

  /// Get statistics about parsed text
  static TextStats getStats(List<WordToken> tokens) {
    return TextStats(
      wordCount: tokens.length,
      sentenceCount: tokens.where((t) => t.hasSentenceEndPunctuation).length,
      paragraphCount: tokens.where((t) => t.isParagraphEnd).length,
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
