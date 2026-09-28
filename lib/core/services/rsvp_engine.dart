/// RSVP Engine - Core playback engine
///
/// Manages word-by-word display with:
/// - Play/pause/stop functionality
/// - Adaptive timing
/// - Progress tracking
/// - Micro-pause insertion
/// - Read-aloud playback, where a [Narrator] moves the words
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/rsvp_settings.dart';
import '../models/word_token.dart';
import '../utils/timing_calculator.dart';
import 'narrator.dart';

/// Playback state for the RSVP engine
enum PlaybackStatus {
  /// Engine not initialized
  uninitialized,

  /// Ready to play (paused at start or after stop)
  ready,

  /// Currently playing
  playing,

  /// Paused during playback
  paused,

  /// Reached end of text
  completed,
}

/// Current state of RSVP playback
class RSVPPlaybackState {
  /// Current playback status
  final PlaybackStatus status;

  /// Currently displayed word token
  final WordToken? currentToken;

  /// Progress through the text (0.0 to 1.0)
  final double progress;

  /// Total number of tokens
  final int totalTokens;

  /// Current token index
  final int currentIndex;

  /// Current words per minute setting
  final int wordsPerMinute;

  /// Number of sentences read in this session
  final int sentencesRead;

  const RSVPPlaybackState({
    this.status = PlaybackStatus.uninitialized,
    this.currentToken,
    this.progress = 0.0,
    this.totalTokens = 0,
    this.currentIndex = 0,
    this.wordsPerMinute = 300,
    this.sentencesRead = 0,
  });

  /// Whether currently playing
  bool get isPlaying => status == PlaybackStatus.playing;

  /// Whether playback has completed
  bool get isComplete => status == PlaybackStatus.completed;

  /// Whether ready to play
  bool get canPlay =>
      status == PlaybackStatus.ready || status == PlaybackStatus.paused || status == PlaybackStatus.completed;

  /// Create a copy with modified fields
  RSVPPlaybackState copyWith({
    PlaybackStatus? status,
    WordToken? currentToken,
    double? progress,
    int? totalTokens,
    int? currentIndex,
    int? wordsPerMinute,
    int? sentencesRead,
  }) {
    return RSVPPlaybackState(
      status: status ?? this.status,
      currentToken: currentToken ?? this.currentToken,
      progress: progress ?? this.progress,
      totalTokens: totalTokens ?? this.totalTokens,
      currentIndex: currentIndex ?? this.currentIndex,
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      sentencesRead: sentencesRead ?? this.sentencesRead,
    );
  }
}

/// RSVP playback engine
///
/// Controls the timing and display of words in RSVP mode.
class RSVPEngine extends ChangeNotifier {
  RSVPPlaybackState _state = const RSVPPlaybackState();
  Timer? _timer;
  List<WordToken> _tokens = [];
  TimingConfig _config = const TimingConfig();

  /// Words shown since the last play/resume (for the speed warm-up)
  int _wordsSincePlay = 0;

  /// Index of the last sentence-end token counted in [RSVPPlaybackState.sentencesRead]
  ///
  /// Resuming after a pause shows the current word again (giving the reader
  /// time to refocus); this keeps that word from being counted twice.
  int _countedSentenceIndex = -1;

  /// Speech that moves the words while playing (read-aloud); null for timed
  /// playback
  Narrator? _narrator;

  /// Number of the current narration; callbacks of older ones are ignored
  int _narration = 0;

  /// Current playback state
  RSVPPlaybackState get state => _state;

  /// The narrator used while playing, if read-aloud is on
  Narrator? get narrator => _narrator;

  /// Use [narrator] for playback (null: timed playback); playback that
  /// was running goes on with the new one
  void setNarrator(Narrator? narrator) {
    if (identical(narrator, _narrator)) return;
    final wasPlaying = _state.isPlaying;
    pause();
    _narrator = narrator;
    if (wasPlaying) play();
  }

  /// Cancel the word timer and stop the narration
  void _halt() {
    _timer?.cancel();
    if (_narrator != null) {
      _narration++;
      _narrator!.stop();
    }
  }

  /// Initialize the engine with tokens and configuration
  void initialize({
    required List<WordToken> tokens,
    TimingConfig config = const TimingConfig(),
    int startIndex = 0,
  }) {
    _halt();
    _countedSentenceIndex = -1;
    _tokens = tokens;
    _config = config;

    if (tokens.isEmpty) {
      _state = const RSVPPlaybackState(status: PlaybackStatus.ready);
      notifyListeners();
      return;
    }

    final clampedIndex = startIndex.clamp(0, tokens.length - 1);

    _state = RSVPPlaybackState(
      status: PlaybackStatus.ready,
      currentToken: tokens[clampedIndex],
      progress: tokens.isNotEmpty ? clampedIndex / tokens.length : 0,
      totalTokens: tokens.length,
      currentIndex: clampedIndex,
      wordsPerMinute: config.baseWPM,
      sentencesRead: 0,
    );

    notifyListeners();
  }

  /// Start or resume playback
  void play() {
    if (_tokens.isEmpty) return;
    if (_state.status == PlaybackStatus.playing) return;

    // If completed, restart from beginning
    if (_state.status == PlaybackStatus.completed) {
      _countedSentenceIndex = -1;
      _state = _state.copyWith(
        currentIndex: 0,
        sentencesRead: 0,
        progress: 0,
        currentToken: _tokens.first,
      );
    }

    _state = _state.copyWith(status: PlaybackStatus.playing);
    _wordsSincePlay = 0;
    notifyListeners();
    if (_narrator != null) {
      _startNarration();
    } else {
      _scheduleNextWord();
    }
  }

  /// Pause playback
  void pause() {
    if (_state.status != PlaybackStatus.playing) return;

    _halt();
    _state = _state.copyWith(status: PlaybackStatus.paused);
    notifyListeners();
  }

  /// Toggle between play and pause
  void togglePlayPause() {
    if (_state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Stop and reset to beginning
  void stop() {
    _halt();
    _countedSentenceIndex = -1;

    if (_tokens.isEmpty) {
      _state = const RSVPPlaybackState(status: PlaybackStatus.ready);
    } else {
      _state = RSVPPlaybackState(
        status: PlaybackStatus.ready,
        currentToken: _tokens.first,
        progress: 0,
        totalTokens: _tokens.length,
        currentIndex: 0,
        wordsPerMinute: _config.baseWPM,
        sentencesRead: 0,
      );
    }

    notifyListeners();
  }

  /// Seek to a specific position (0.0 to 1.0)
  void seekTo(double progress) {
    if (_tokens.isEmpty) return;
    seekToIndex((progress * _tokens.length).floor());
  }

  /// Seek to a specific word index
  void seekToIndex(int index) {
    if (_tokens.isEmpty) return;

    final wasPlaying = _state.isPlaying;
    _halt();

    final newIndex = index.clamp(0, _tokens.length - 1);

    _state = _state.copyWith(
      status: PlaybackStatus.paused,
      currentToken: _tokens[newIndex],
      progress: newIndex / _tokens.length,
      currentIndex: newIndex,
    );

    notifyListeners();

    if (wasPlaying) {
      play();
    }
  }

  /// Skip forward by number of words
  void skipForward(int words) {
    if (_tokens.isEmpty) return;
    seekToIndex(_state.currentIndex + words);
  }

  /// Skip backward by number of words
  void skipBackward(int words) {
    if (_tokens.isEmpty) return;
    seekToIndex(_state.currentIndex - words);
  }

  /// Update reading speed (WPM)
  void setSpeed(int wpm) {
    final clampedWPM = wpm.clamp(
      RSVPSettings.minWordsPerMinute,
      RSVPSettings.maxWordsPerMinute,
    );
    _config = _config.copyWith(baseWPM: clampedWPM);
    _state = _state.copyWith(wordsPerMinute: clampedWPM);
    notifyListeners();
  }

  /// Increase speed by increment
  void increaseSpeed([int increment = RSVPSettings.wordsPerMinuteStep]) {
    setSpeed(_state.wordsPerMinute + increment);
  }

  /// Decrease speed by increment
  void decreaseSpeed([int increment = RSVPSettings.wordsPerMinuteStep]) {
    setSpeed(_state.wordsPerMinute - increment);
  }

  /// Update timing configuration
  void updateConfig(TimingConfig config) {
    _config = config;
    _state = _state.copyWith(wordsPerMinute: config.baseWPM);
    notifyListeners();
  }

  /// Speak from the current word on, showing each word as it is spoken
  void _startNarration() {
    final narration = ++_narration;
    _narrator!.speak(
      _tokens,
      _state.currentIndex,
      onWord: (index) {
        if (narration != _narration || !_state.isPlaying) return;
        final i = index.clamp(0, _tokens.length - 1);
        _state = _state.copyWith(currentIndex: i, currentToken: _tokens[i], progress: i / _tokens.length);
        notifyListeners();
      },
      onDone: () {
        if (narration != _narration || !_state.isPlaying) return;
        _state = _state.copyWith(
          status: PlaybackStatus.completed,
          currentIndex: _tokens.length - 1,
          currentToken: _tokens.last,
          progress: 1.0,
        );
        notifyListeners();
      },
    );
  }

  /// Schedule display of the next word
  void _scheduleNextWord() {
    final token = _tokens[_state.currentIndex];

    // Calculate duration for this word
    int duration = TimingCalculator.calculateDuration(
      config: _config,
      word: token.word,
      isParagraphEnd: token.isParagraphEnd,
      isSentenceEnd: token.hasSentenceEndPunctuation,
    );

    // Start slower after play/resume, reaching full speed after a few words
    duration = (duration * _config.warmUpFactor(_wordsSincePlay)).round();
    _wordsSincePlay += token.chunkSize; // a chunk holds several words

    // Track sentences and add micro-pause if needed
    int sentencesRead = _state.sentencesRead;
    if (token.hasSentenceEndPunctuation && _state.currentIndex != _countedSentenceIndex) {
      _countedSentenceIndex = _state.currentIndex;
      sentencesRead++;
      if (TimingCalculator.shouldInsertMicroPause(
        sentencesRead,
        _config.microPauseInterval,
      )) {
        duration += _config.microPauseDuration;
      }
    }

    // Update state with current word
    _state = _state.copyWith(
      currentToken: token,
      progress: _state.currentIndex / _tokens.length,
      sentencesRead: sentencesRead,
    );
    notifyListeners();

    // Schedule next word
    _timer = Timer(Duration(milliseconds: duration), () {
      if (_state.status != PlaybackStatus.playing) return;

      final nextIndex = _state.currentIndex + 1;
      if (nextIndex >= _tokens.length) {
        // Finished reading - stay on the last word so the index remains valid
        _state = _state.copyWith(status: PlaybackStatus.completed, progress: 1.0);
        notifyListeners();
        return;
      }

      _state = _state.copyWith(currentIndex: nextIndex);
      _scheduleNextWord();
    });
  }

  @override
  void dispose() {
    _halt();
    super.dispose();
  }
}
