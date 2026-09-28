/// Timing Calculator for RSVP display
///
/// Calculates adaptive display duration for each word based on:
/// - Word length (shorter words = faster)
/// - Punctuation (pauses for commas, periods, etc.)
/// - Special cases (URLs, ellipsis)
library;

import 'orp_calculator.dart';

/// Configuration for timing calculations
class TimingConfig {
  /// Base words per minute
  final int baseWPM;

  /// Whether to apply adaptive speed based on word length
  final bool adaptiveSpeed;

  /// Number of sentences between micro-pauses
  final int microPauseInterval;

  /// Duration of micro-pause in milliseconds
  final int microPauseDuration;

  /// Start slower after play/resume and speed up to [baseWPM]
  final bool warmUp;

  const TimingConfig({
    this.baseWPM = 300,
    this.adaptiveSpeed = true,
    this.microPauseInterval = 7,
    this.microPauseDuration = 300,
    this.warmUp = false,
  });

  /// Words over which the warm-up reaches full speed
  static const warmUpWords = 20;

  /// Speed of the first word of the warm-up, as a share of [baseWPM]
  static const warmUpStartSpeed = 0.6;

  /// Duration factor for the [wordsShown]th word after play (0-based):
  /// 1 / 0.6 at the start, 1.0 from [warmUpWords] on
  double warmUpFactor(int wordsShown) {
    if (!warmUp || wordsShown >= warmUpWords) return 1.0;
    final speed = warmUpStartSpeed + (1 - warmUpStartSpeed) * wordsShown / warmUpWords;
    return 1 / speed;
  }

  TimingConfig copyWith({
    int? baseWPM,
    bool? adaptiveSpeed,
    int? microPauseInterval,
    int? microPauseDuration,
    bool? warmUp,
  }) {
    return TimingConfig(
      baseWPM: baseWPM ?? this.baseWPM,
      adaptiveSpeed: adaptiveSpeed ?? this.adaptiveSpeed,
      microPauseInterval: microPauseInterval ?? this.microPauseInterval,
      microPauseDuration: microPauseDuration ?? this.microPauseDuration,
      warmUp: warmUp ?? this.warmUp,
    );
  }
}

/// Punctuation types for timing adjustments
enum PunctuationType {
  /// No punctuation
  none,

  /// Sentence end: . ! ?
  sentenceEnd,

  /// Mid-sentence pause: , : ;
  midSentence,

  /// Ellipsis: ...
  ellipsis,

  /// Long dash
  longDash,

  /// Opening bracket: ( [ {
  openingBracket,

  /// Closing bracket: ) ] }
  closingBracket,
}

/// Calculator for word display timing
class TimingCalculator {
  /// Word length multipliers for adaptive speed
  static const _lengthMultipliers = <int, double>{
    2: 0.75, // Very short: ve, bu, o
    4: 0.90, // Short: kitap, masa
    6: 1.00, // Medium (base)
    9: 1.15, // Long
    12: 1.30, // Very long
  };

  /// Punctuation pause durations in milliseconds
  static const _punctuationPauses = <PunctuationType, int>{
    PunctuationType.none: 0,
    PunctuationType.sentenceEnd: 200,
    PunctuationType.midSentence: 150,
    PunctuationType.ellipsis: 350,
    PunctuationType.longDash: 100,
    PunctuationType.openingBracket: 50,
    PunctuationType.closingBracket: 50,
  };

  /// Extra pause for paragraph end
  static const int _paragraphPause = 400;

  /// Extra time for URLs (they're long single tokens)
  static const int _urlExtraTime = 300;

  /// Closing bracket and quote characters
  static const _closingBrackets = ')]}\u0022\u0027\u00BB\u2019\u201D';

  /// Opening bracket characters
  static const _openingBrackets = '([\u0022\u00AB\u2018\u201C\u201E{';

  /// Detect punctuation type at end of word
  ///
  /// Closing quotes and brackets are looked past, so 'dedi."' ends a
  /// sentence and '(sessizce),' is a mid-sentence pause.
  static PunctuationType detectPunctuation(String word) {
    if (word.isEmpty) return PunctuationType.none;

    var end = word.length;
    while (end > 0 && _closingBrackets.contains(word[end - 1])) {
      end--;
    }
    final core = word.substring(0, end);

    // Check for ellipsis
    if (core.endsWith('...') || core.endsWith('\u2026')) {
      return PunctuationType.ellipsis;
    }

    if (core.isNotEmpty) {
      final lastChar = core[core.length - 1];

      // Sentence endings
      if ('.!?'.contains(lastChar)) {
        return PunctuationType.sentenceEnd;
      }

      // Mid-sentence pauses
      if (',:;'.contains(lastChar)) {
        return PunctuationType.midSentence;
      }

      // Long dash (em dash, en dash)
      if (lastChar == '\u2014' || lastChar == '\u2013') {
        return PunctuationType.longDash;
      }
    }

    // Closing brackets
    if (end < word.length) {
      return PunctuationType.closingBracket;
    }

    // Check first char for opening brackets
    final firstChar = word[0];
    if (_openingBrackets.contains(firstChar)) {
      return PunctuationType.openingBracket;
    }

    return PunctuationType.none;
  }

  /// Check if word is a URL
  static bool isUrl(String word) {
    return word.startsWith('http://') ||
        word.startsWith('https://') ||
        word.startsWith('www.') ||
        (word.contains('@') && word.contains('.')); // email
  }

  /// Get length multiplier for adaptive speed
  static double _getLengthMultiplier(int effectiveLength) {
    if (effectiveLength <= 2) return _lengthMultipliers[2]!;
    if (effectiveLength <= 4) return _lengthMultipliers[4]!;
    if (effectiveLength <= 6) return _lengthMultipliers[6]!;
    if (effectiveLength <= 9) return _lengthMultipliers[9]!;
    return _lengthMultipliers[12]!;
  }

  /// Calculate display duration for a word
  ///
  /// [config] - Timing configuration
  /// [word] - The word to calculate duration for
  /// [isParagraphEnd] - Whether this word ends a paragraph
  ///
  /// Returns duration in milliseconds
  static int calculateDuration({
    required TimingConfig config,
    required String word,
    bool isParagraphEnd = false,
  }) {
    // Base duration from WPM (milliseconds per word)
    final baseDuration = (60000 / config.baseWPM).round();

    int duration = baseDuration;

    // Apply length multiplier if adaptive speed is enabled
    if (config.adaptiveSpeed) {
      final effectiveLength = ORPCalculator.getEffectiveLength(word);
      final multiplier = _getLengthMultiplier(effectiveLength);
      duration = (baseDuration * multiplier).round();
    }

    // Add punctuation pause
    final punctuation = detectPunctuation(word);
    duration += _punctuationPauses[punctuation]!;

    // Add paragraph pause
    if (isParagraphEnd) {
      duration += _paragraphPause;
    }

    // Add extra time for URLs
    if (isUrl(word)) {
      duration += _urlExtraTime;
    }

    return duration;
  }

  /// Check if micro-pause should be inserted
  ///
  /// Returns true if we've read [interval] sentences since last pause
  static bool shouldInsertMicroPause(int sentenceCount, int interval) {
    return interval > 0 && sentenceCount > 0 && sentenceCount % interval == 0;
  }

  /// Check if word ends a sentence
  static bool isSentenceEnd(String word) {
    return detectPunctuation(word) == PunctuationType.sentenceEnd;
  }
}
