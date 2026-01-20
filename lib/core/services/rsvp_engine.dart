/// RSVP Engine - Core playback engine
///
/// Manages word-by-word display with:
/// - Play/pause/stop functionality
/// - Adaptive timing
/// - Progress tracking
/// - Micro-pause insertion
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/word_token.dart';
import '../utils/timing_calculator.dart';

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
      status == PlaybackStatus.ready ||
      status == PlaybackStatus.paused ||
      status == PlaybackStatus.completed;

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

  /// Current playback state
  RSVPPlaybackState get state => _state;

  /// Initialize the engine with tokens and configuration
  void initialize({
    required List<WordToken> tokens,
    TimingConfig config = const TimingConfig(),
    int startIndex = 0,
  }) {
    _timer?.cancel();
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
      _state = _state.copyWith(
        currentIndex: 0,
        sentencesRead: 0,
        progress: 0,
        currentToken: _tokens.first,
      );
    }

    _state = _state.copyWith(status: PlaybackStatus.playing);
    notifyListeners();
    _scheduleNextWord();
  }

  /// Pause playback
  void pause() {
    if (_state.status != PlaybackStatus.playing) return;

    _timer?.cancel();
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
    _timer?.cancel();

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

    final wasPlaying = _state.isPlaying;
    _timer?.cancel();

    final newIndex = (progress * _tokens.length).floor().clamp(0, _tokens.length - 1);

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

  /// Seek to a specific word index
  void seekToIndex(int index) {
    if (_tokens.isEmpty) return;

    final clampedIndex = index.clamp(0, _tokens.length - 1);
    seekTo(clampedIndex / _tokens.length);
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
    final clampedWPM = wpm.clamp(50, 1000);
    _config = _config.copyWith(baseWPM: clampedWPM);
    _state = _state.copyWith(wordsPerMinute: clampedWPM);
    notifyListeners();
  }

  /// Increase speed by increment
  void increaseSpeed([int increment = 50]) {
    setSpeed(_state.wordsPerMinute + increment);
  }

  /// Decrease speed by increment
  void decreaseSpeed([int increment = 50]) {
    setSpeed(_state.wordsPerMinute - increment);
  }

  /// Update timing configuration
  void updateConfig(TimingConfig config) {
    _config = config;
    _state = _state.copyWith(wordsPerMinute: config.baseWPM);
    notifyListeners();
  }

  /// Schedule display of the next word
  void _scheduleNextWord() {
    if (_state.currentIndex >= _tokens.length) {
      // Finished reading
      _state = _state.copyWith(status: PlaybackStatus.completed);
      notifyListeners();
      return;
    }

    final token = _tokens[_state.currentIndex];

    // Calculate duration for this word
    int duration = TimingCalculator.calculateDuration(
      config: _config,
      word: token.word,
      isParagraphEnd: token.isParagraphEnd,
    );

    // Track sentences and add micro-pause if needed
    int sentencesRead = _state.sentencesRead;
    if (token.hasSentenceEndPunctuation) {
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
      _state = _state.copyWith(currentIndex: nextIndex);

      _scheduleNextWord();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
