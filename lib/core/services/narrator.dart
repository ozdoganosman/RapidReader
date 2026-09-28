/// Narrator
///
/// Read-aloud playback: a narrator speaks the text and reports which word
/// it is at, and the RSVP engine shows that word instead of timing the
/// words itself.
library;

import '../models/word_token.dart';

/// Speaks tokens and reports its position
abstract class Narrator {
  /// Speak [tokens] from index [start] on. [onWord] is called with the index
  /// of the word being spoken, [onDone] once the last word was spoken.
  ///
  /// A new call or [stop] ends the previous one; its callbacks are not
  /// called after that.
  void speak(
    List<WordToken> tokens,
    int start, {
    required void Function(int index) onWord,
    required void Function() onDone,
  });

  /// Stop speaking
  void stop();

  /// Release the speech engine
  void dispose();
}

/// A speech speed as shown to the user: 1x, 1,25x, 0,75x
String speechRateLabel(double rate) {
  var text = rate.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${text.replaceAll('.', ',')}x';
}

/// A part of the text spoken as one utterance (a sentence, or a slice of a
/// very long one), with the position of each token in the spoken text
class SpeechChunk {
  /// Longest chunk in tokens, for sentences without punctuation
  static const maxTokens = 40;

  /// Index of the first token
  final int start;

  /// Index after the last token
  final int end;

  /// The tokens joined with spaces
  final String text;

  /// Offset of each token in [text]
  final List<int> offsets;

  const SpeechChunk._(this.start, this.end, this.text, this.offsets);

  /// The chunk that starts at token [start]: up to the end of its sentence
  /// or paragraph
  factory SpeechChunk.from(List<WordToken> tokens, int start) {
    final buffer = StringBuffer();
    final offsets = <int>[];
    var i = start;
    while (i < tokens.length) {
      final token = tokens[i];
      if (buffer.isNotEmpty) buffer.write(' ');
      offsets.add(buffer.length);
      buffer.write(token.word);
      i++;
      if (token.hasSentenceEndPunctuation || token.isParagraphEnd || i - start >= maxTokens) break;
    }
    return SpeechChunk._(start, i, buffer.toString(), offsets);
  }

  /// Whether the chunk has anything to say (not only punctuation)
  bool get isSpeakable => RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text);

  /// Index of the token at character [offset] of [text]
  int indexAt(int offset) {
    var low = 0;
    var high = offsets.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (offsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return start + low;
  }
}
