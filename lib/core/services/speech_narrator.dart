/// Speech Narrator
///
/// Reads the text aloud with the device's text-to-speech voice
/// (flutter_tts), one sentence per utterance. The shown word follows the
/// voice's word events; voices that send none (some browser voices) are
/// followed by an estimate from the speaking speed.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/rsvp_settings.dart';
import '../models/word_token.dart';
import 'narrator.dart';

class SpeechNarrator implements Narrator {
  /// Language of the voice
  static const language = 'tr-TR';

  /// Characters per second at speech rate 1.0, for the estimate
  static const normalCharsPerSecond = 14.0;

  /// Words per minute at speech rate 1.0, for the reading time estimate
  static const normalWordsPerMinute = 120;

  final FlutterTts _tts;

  /// Called when the voice reports an error
  final void Function(String message)? onError;

  /// Speech speed (1.0 is the voice's normal speed); applies from the next
  /// sentence on
  double rate;

  SpeechNarrator({FlutterTts? tts, this.rate = 1.0, this.onError}) : _tts = tts ?? FlutterTts() {
    _tts.setStartHandler(_onStart);
    _tts.setProgressHandler(_onProgress);
    _tts.setErrorHandler((message) {
      if (_current != null) onError?.call('$message');
    });
  }

  /// Whether the device has a voice for [language]
  ///
  /// (flutter_tts sends its events to the newest instance, so this asks the
  /// narrator's own one.)
  Future<bool> isAvailable() async {
    // Browsers load their voices after the page; ask again for a moment
    for (var attempt = 0; attempt < (kIsWeb ? 4 : 1); attempt++) {
      try {
        final available = await _tts
            .isLanguageAvailable(language)
            // No speech engine on the device: the call never returns
            .timeout(const Duration(seconds: 5), onTimeout: () => false);
        if (available == true) return true;
      } catch (_) {
        return false;
      }
      if (kIsWeb) await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  /// The value flutter_tts expects for [rate]: its mobile scale has the
  /// normal speed at 0.5, browsers at 1.0
  static double platformRate(double rate, {bool web = kIsWeb}) {
    final clamped = rate.clamp(RSVPSettings.minSpeechRate, RSVPSettings.maxSpeechRate).toDouble();
    return web ? clamped : clamped / 2;
  }

  bool _prepared = false;

  /// Number of the current [speak] call
  int _session = 0;

  /// The utterance being spoken
  _Utterance? _current;

  /// Finishes when the last stop has taken effect
  Future<void> _stopped = Future.value();

  /// Whether the voice sends word events (then no estimate is needed)
  bool _hasWordEvents = false;

  Timer? _estimate;

  @override
  void speak(
    List<WordToken> tokens,
    int start, {
    required void Function(int index) onWord,
    required void Function() onDone,
  }) {
    if (_current != null) stop();
    _run(++_session, tokens, start, onWord, onDone);
  }

  Future<void> _run(
    int session,
    List<WordToken> tokens,
    int start,
    void Function(int index) onWord,
    void Function() onDone,
  ) async {
    await _stopped;
    if (!_prepared) {
      _prepared = true;
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(language);
    }

    var index = start;
    while (session == _session && index < tokens.length) {
      final chunk = SpeechChunk.from(tokens, index);
      index = chunk.end;
      if (!chunk.isSpeakable) continue;

      onWord(chunk.start);
      await _tts.setSpeechRate(platformRate(rate));
      if (session != _session) return;
      _current = _Utterance(chunk, onWord, rate);
      await _tts.speak(chunk.text);
      _estimate?.cancel();
      // Stopped (or replaced by a new call) while speaking
      if (session != _session) return;
      _current = null;
    }
    if (session == _session) onDone();
  }

  void _onStart() {
    final utterance = _current;
    _estimate?.cancel();
    if (utterance == null || _hasWordEvents) return;

    // Follow the voice by time until (if ever) it sends word events
    const interval = Duration(milliseconds: 80);
    final charsPerSecond = normalCharsPerSecond * utterance.rate;
    var shown = utterance.chunk.start;
    _estimate = Timer.periodic(interval, (timer) {
      if (!identical(_current, utterance) || _hasWordEvents) {
        timer.cancel();
        return;
      }
      final elapsed = timer.tick * interval.inMilliseconds;
      final index = utterance.chunk.indexAt((elapsed * charsPerSecond / 1000).floor());
      if (index != shown) {
        shown = index;
        utterance.onWord(index);
      }
    });
  }

  void _onProgress(String text, int start, int end, String word) {
    final utterance = _current;
    if (utterance == null || text != utterance.chunk.text) return;
    // Old Android versions report the whole text once at offset 0
    if (start > 0) {
      _hasWordEvents = true;
      _estimate?.cancel();
    }
    utterance.onWord(utterance.chunk.indexAt(start));
  }

  @override
  void stop() {
    _session++;
    _estimate?.cancel();
    final wasSpeaking = _current != null;
    _current = null;
    if (!wasSpeaking) return;
    _stopped = _tts.stop().then<void>((_) async {
      // A browser reports the stop a little later, and ignores new speech
      // until then
      if (kIsWeb) await Future<void>.delayed(const Duration(milliseconds: 150));
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    stop();
  }
}

class _Utterance {
  final SpeechChunk chunk;
  final void Function(int index) onWord;
  final double rate;

  _Utterance(this.chunk, this.onWord, this.rate);
}
