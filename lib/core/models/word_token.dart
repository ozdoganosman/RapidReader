/// Word Token model for RSVP display
///
/// Represents a single word or chunk to be displayed in RSVP mode.
library;

import 'package:equatable/equatable.dart';

/// A token representing a word or chunk for RSVP display
class WordToken extends Equatable {
  /// The actual word/text to display
  final String word;

  /// Index of this token in the full text
  final int index;

  /// Whether this word ends with sentence punctuation (. ! ?)
  final bool hasSentenceEndPunctuation;

  /// Whether this word ends with mid-sentence punctuation (, : ;)
  final bool hasMidSentencePunctuation;

  /// Whether this is the last word in a paragraph
  final bool isParagraphEnd;

  /// The sentence number this word belongs to
  final int sentenceNumber;

  /// Whether this token is a chunk of multiple words
  final bool isChunk;

  /// Number of words in this chunk (1 if not a chunk)
  final int chunkSize;

  /// Whether this token is a URL or email
  final bool isUrl;

  const WordToken({
    required this.word,
    required this.index,
    this.hasSentenceEndPunctuation = false,
    this.hasMidSentencePunctuation = false,
    this.isParagraphEnd = false,
    this.sentenceNumber = 0,
    this.isChunk = false,
    this.chunkSize = 1,
    this.isUrl = false,
  });

  /// Create a copy with modified fields
  WordToken copyWith({
    String? word,
    int? index,
    bool? hasSentenceEndPunctuation,
    bool? hasMidSentencePunctuation,
    bool? isParagraphEnd,
    int? sentenceNumber,
    bool? isChunk,
    int? chunkSize,
    bool? isUrl,
  }) {
    return WordToken(
      word: word ?? this.word,
      index: index ?? this.index,
      hasSentenceEndPunctuation: hasSentenceEndPunctuation ?? this.hasSentenceEndPunctuation,
      hasMidSentencePunctuation: hasMidSentencePunctuation ?? this.hasMidSentencePunctuation,
      isParagraphEnd: isParagraphEnd ?? this.isParagraphEnd,
      sentenceNumber: sentenceNumber ?? this.sentenceNumber,
      isChunk: isChunk ?? this.isChunk,
      chunkSize: chunkSize ?? this.chunkSize,
      isUrl: isUrl ?? this.isUrl,
    );
  }

  @override
  List<Object?> get props => [
        word,
        index,
        hasSentenceEndPunctuation,
        hasMidSentencePunctuation,
        isParagraphEnd,
        sentenceNumber,
        isChunk,
        chunkSize,
        isUrl,
      ];

  @override
  String toString() => 'WordToken($word, idx:$index, sent:$sentenceNumber)';
}
