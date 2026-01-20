/// Text Parser for RSVP display
///
/// Tokenizes text into words with proper handling of:
/// - Turkish apostrophes (') - keeps words together
/// - Hyphens (-) - keeps words together
/// - Slashes (/) - splits words
/// - Parentheses, brackets, quotes - separate tokens
/// - URLs and emails - single tokens
library;

import '../models/word_token.dart';

/// Parser for converting raw text into RSVP tokens
class TextParser {
  /// Regex patterns for special tokens that should not be split
  static final _urlPattern = RegExp(r'https?://\S+|www\.\S+');
  static final _emailPattern = RegExp(r'\S+@\S+\.\S+');

  /// Characters that become separate tokens but stay attached visually
  static const _separateTokens = {
    '(', ')', '[', ']', '{', '}',
    '"', // double quote
    "'", // single quote
    '\u201C', '\u201D', // curly double quotes
    '\u2018', '\u2019', // curly single quotes
    '\u00AB', '\u00BB', // guillemets
  };

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

    return tokens;
  }

  /// Process a single word, handling special punctuation
  static List<String> _processWord(String word) {
    final results = <String>[];

    // Extract leading separate tokens
    String remaining = word;
    while (remaining.isNotEmpty && _separateTokens.contains(remaining[0])) {
      results.add(remaining[0]);
      remaining = remaining.substring(1);
    }

    if (remaining.isEmpty) return results;

    // Extract trailing separate tokens (but keep sentence punctuation attached)
    final trailing = <String>[];
    while (remaining.isNotEmpty) {
      final lastChar = remaining[remaining.length - 1];
      if (_separateTokens.contains(lastChar)) {
        trailing.insert(0, lastChar);
        remaining = remaining.substring(0, remaining.length - 1);
      } else {
        break;
      }
    }

    if (remaining.isEmpty) {
      results.addAll(trailing);
      return results;
    }

    // Handle slashes - split the word
    if (remaining.contains('/')) {
      final parts = remaining.split('/');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          results.add(parts[i]);
        }
      }
    }
    // Handle backslashes - split the word
    else if (remaining.contains('\\')) {
      final parts = remaining.split('\\');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          results.add(parts[i]);
        }
      }
    }
    // Normal word (apostrophes and hyphens stay intact)
    else {
      results.add(remaining);
    }

    // Add trailing tokens
    results.addAll(trailing);

    return results;
  }

  /// Apply chunking to group multiple words together
  static List<WordToken> _applyChunking(List<WordToken> tokens, int chunkSize) {
    final chunked = <WordToken>[];

    for (int i = 0; i < tokens.length; i += chunkSize) {
      final chunkEnd = (i + chunkSize).clamp(0, tokens.length);
      final chunk = tokens.sublist(i, chunkEnd);

      // Skip standalone punctuation in chunks
      final meaningfulTokens = chunk.where((t) => t.word.length > 1 || !_isPunctuation(t.word)).toList();
      if (meaningfulTokens.isEmpty) {
        // If only punctuation, still add it
        for (final token in chunk) {
          chunked.add(token.copyWith(index: chunked.length));
        }
        continue;
      }

      // Combine words in chunk
      final combinedWord = chunk.map((t) => t.word).join(' ');

      // Inherit metadata from last meaningful token
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

  /// Check if string is just punctuation
  static bool _isPunctuation(String s) {
    if (s.isEmpty) return false;
    return _separateTokens.contains(s) || '.!?,;:'.contains(s);
  }

  /// Check if word ends with sentence punctuation
  static bool _endsWithSentencePunct(String word) {
    if (word.isEmpty) return false;
    final last = word[word.length - 1];
    return '.!?'.contains(last) || word.endsWith('...');
  }

  /// Check if word ends with mid-sentence punctuation
  static bool _endsWithMidPunct(String word) {
    if (word.isEmpty) return false;
    final last = word[word.length - 1];
    return ',;:'.contains(last);
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
