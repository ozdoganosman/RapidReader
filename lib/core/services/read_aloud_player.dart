/// Read Aloud Player
///
/// Reads a text aloud with the device's Turkish voice for the listening
/// mode, paragraph by paragraph. On Android and iOS all the remaining
/// paragraphs are queued at once: the voice goes on without a pause between
/// them, and with the screen off. Browsers take one paragraph at a time.
/// The paragraph and the word being spoken are reported for the highlight.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/rsvp_settings.dart';

/// A speech speed as shown to the user: 1x, 1,25x, 0,75x
String speechRateLabel(double rate) {
  var text = rate.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${text.replaceAll('.', ',')}x';
}

class ReadAloudPlayer extends ChangeNotifier {
  /// Language of the voice
  static const language = 'tr-TR';

  /// Longest text given to the voice at once (Android takes up to 4000)
  static const maxUtteranceLength = 3000;

  final FlutterTts _tts;

  /// Queue all paragraphs at once (mobile) instead of one at a time (web)
  final bool _queue;

  /// The text, one paragraph per entry
  final List<String> paragraphs;

  /// Called when the voice reports an error (playback has stopped)
  void Function(String message)? onError;

  /// Called after the last paragraph was read
  VoidCallback? onFinished;

  ReadAloudPlayer({
    required this.paragraphs,
    FlutterTts? tts,
    double rate = 1.0,
    bool? queue,
  })  : _tts = tts ?? FlutterTts(),
        _rate = rate,
        _queue = queue ?? !kIsWeb {
    _tts.setStartHandler(() => _waitingForStart = false);
    _tts.setProgressHandler(_onProgress);
    _tts.setCompletionHandler(_onComplete);
    _tts.setErrorHandler((message) {
      if (!_playing) return;
      _halt();
      _playing = false;
      notifyListeners();
      onError?.call('$message');
    });
  }

  int _paragraph = 0;
  int? _wordStart;
  int? _wordEnd;
  bool _playing = false;
  double _rate;

  /// Paragraph being read (or where reading goes on)
  int get paragraph => _paragraph;

  /// The word being spoken, as offsets in [paragraph]'s text; null when
  /// the voice sends no word positions
  int? get wordStart => _wordStart;
  int? get wordEnd => _wordEnd;

  bool get isPlaying => _playing;

  /// Speech speed (1.0 is the voice's normal speed)
  double get rate => _rate;

  /// The utterances given to the voice, in order
  List<_Utterance> _utterances = const [];

  /// The utterance being spoken
  int _active = 0;

  /// Number of the current [play]; work of an older one stops
  int _session = 0;

  bool _prepared = false;

  /// Finishes when the last stop has taken effect
  Future<void> _stopped = Future.value();

  /// Queued but not started yet: completions of a stopped queue are ignored
  bool _waitingForStart = false;

  /// Whether the device has a voice for [language]
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

  /// Move to paragraph [index] without reading (or read from there if
  /// playing)
  void seek(int index) {
    final target = index.clamp(0, paragraphs.length - 1);
    if (_playing) {
      play(from: target);
      return;
    }
    _paragraph = target;
    _wordStart = _wordEnd = null;
    notifyListeners();
  }

  /// Read from paragraph [from], or from the current word
  Future<void> play({int? from}) async {
    if (paragraphs.isEmpty) return;
    if (from != null) {
      _paragraph = from.clamp(0, paragraphs.length - 1);
      _wordStart = _wordEnd = null;
    }
    if (_playing) _halt();
    final session = ++_session;
    _playing = true;
    notifyListeners();

    await _stopped;
    try {
      if (!_prepared) {
        _prepared = true;
        await _tts.setLanguage(language);
        await _tts.awaitSpeakCompletion(!_queue);
        if (_queue) {
          try {
            await _tts.setQueueMode(1); // Android: add to the queue
          } catch (_) {
            // iOS queues on its own
          }
        }
      }
      await _tts.setSpeechRate(platformRate(_rate));
    } catch (_) {
      // The voice reports its own errors when speaking
    }
    if (session != _session) return;

    _utterances = _utterancesFrom(_paragraph, _wordStart ?? 0);
    _active = 0;
    if (_utterances.isEmpty) {
      _finish();
      return;
    }

    if (_queue) {
      _waitingForStart = true;
      for (final utterance in _utterances) {
        await _tts.speak(utterance.text);
        if (session != _session) return;
      }
    } else {
      for (var i = 0; i < _utterances.length; i++) {
        _active = i;
        _show(_utterances[i].paragraph);
        await _tts.speak(_utterances[i].text);
        if (session != _session) return;
      }
      _finish();
    }
  }

  /// Stop reading; [play] goes on from the current word
  void pause() {
    if (!_playing) return;
    _halt();
    _playing = false;
    notifyListeners();
  }

  /// Change the speech speed (the reading goes on from the current word)
  void setRate(double rate) {
    _rate = rate.clamp(RSVPSettings.minSpeechRate, RSVPSettings.maxSpeechRate).toDouble();
    if (_playing) {
      play();
    } else {
      notifyListeners();
    }
  }

  void _halt() {
    _session++;
    _waitingForStart = false;
    _utterances = const [];
    _stopped = _tts.stop().then<void>((_) async {
      // A browser reports the stop a little later, and ignores new speech
      // until then
      if (kIsWeb) await Future<void>.delayed(const Duration(milliseconds: 150));
    }).catchError((Object _) {});
  }

  void _finish() {
    _playing = false;
    _utterances = const [];
    _wordStart = _wordEnd = null;
    notifyListeners();
    onFinished?.call();
  }

  void _show(int paragraph) {
    _paragraph = paragraph;
    _wordStart = _wordEnd = null;
    notifyListeners();
  }

  void _onProgress(String text, int start, int end, String word) {
    if (!_playing) return;
    // The utterance the voice is at (found by its text: the events carry no id)
    var index = _active;
    while (index < _utterances.length && _utterances[index].text != text) {
      index++;
    }
    if (index == _utterances.length) return;
    _active = index;
    final utterance = _utterances[index];
    _paragraph = utterance.paragraph;
    _wordStart = utterance.offset + start;
    _wordEnd = utterance.offset + end;
    notifyListeners();
  }

  void _onComplete() {
    // One at a time (web): the loop in [play] moves on
    if (!_queue || !_playing || _waitingForStart) return;
    _active++;
    if (_active >= _utterances.length) {
      _finish();
    } else {
      _show(_utterances[_active].paragraph);
    }
  }

  /// The text from [paragraph] (at character [offset]) to the end, in
  /// utterances of at most [maxUtteranceLength] characters
  List<_Utterance> _utterancesFrom(int paragraph, int offset) {
    final result = <_Utterance>[];
    for (var p = paragraph; p < paragraphs.length; p++) {
      final text = paragraphs[p];
      var start = p == paragraph ? offset.clamp(0, text.length) : 0;
      while (start < text.length) {
        // skip spaces before the piece
        while (start < text.length && text[start] == ' ') {
          start++;
        }
        if (start >= text.length) break;
        var end = text.length;
        if (end - start > maxUtteranceLength) {
          // cut at the last sentence end, else the last space, in the limit
          final window = text.substring(start, start + maxUtteranceLength);
          final sentence = window.lastIndexOf(RegExp(r'[.!?…]\s'));
          final space = window.lastIndexOf(' ');
          end = start + (sentence > 0 ? sentence + 1 : (space > 0 ? space : maxUtteranceLength));
        }
        final piece = text.substring(start, end);
        if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(piece)) {
          result.add(_Utterance(p, start, piece));
        }
        start = end;
      }
    }
    return result;
  }

  @override
  void dispose() {
    if (_playing) _halt();
    super.dispose();
  }
}

class _Utterance {
  final int paragraph;

  /// Where [text] starts in the paragraph
  final int offset;
  final String text;

  const _Utterance(this.paragraph, this.offset, this.text);
}
