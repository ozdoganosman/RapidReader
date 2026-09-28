import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/word_token.dart';
import 'package:rapid_reader/core/services/narrator.dart';
import 'package:rapid_reader/core/services/speech_narrator.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';

const _channel = MethodChannel('flutter_tts');

/// A paragraph of only a dash, then a sentence
const _dashThenWord = [
  WordToken(word: '—', index: 0, isParagraphEnd: true),
  WordToken(word: 'Kelime.', index: 1, hasSentenceEndPunctuation: true),
];
const _codec = StandardMethodCodec();

/// A fake flutter_tts platform side: records what is spoken; each speech
/// finishes when the test completes it
class _FakeTts {
  final WidgetTester tester;
  final spoken = <String>[];
  final calls = <String>[];
  Completer<int>? _speech;
  bool available = true;

  _FakeTts(this.tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'speak':
          spoken.add(call.arguments as String);
          _speech = Completer<int>();
          return _speech!.future;
        case 'stop':
          _speech?.complete(0);
          _speech = null;
          return 1;
        case 'isLanguageAvailable':
          return available;
      }
      return 1;
    });
  }

  Future<void> finishSpeech() async {
    _speech?.complete(1);
    _speech = null;
    await tester.pump();
  }

  Future<void> send(String method, [Object? arguments]) async {
    await tester.binding.defaultBinaryMessenger
        .handlePlatformMessage(_channel.name, _codec.encodeMethodCall(MethodCall(method, arguments)), (_) {});
    await tester.pump();
  }

  Future<void> progress(String text, int start) =>
      send('speak.onProgress', {'text': text, 'start': '$start', 'end': '${start + 1}', 'word': ''});
}

void main() {
  group('SpeechChunk', () {
    test('ends at the end of a sentence', () {
      final tokens = TextParser.parse('Bir iki. Üç dört beş.');
      final first = SpeechChunk.from(tokens, 0);
      expect(first.text, 'Bir iki.');
      expect(first.end, 2);

      final second = SpeechChunk.from(tokens, first.end);
      expect(second.text, 'Üç dört beş.');
      expect(second.start, 2);
      expect(second.end, 5);
    });

    test('ends at a paragraph break and after at most maxTokens', () {
      final paragraphs = SpeechChunk.from(TextParser.parse('Başlık\n\nMetin burada'), 0);
      expect(paragraphs.text, 'Başlık');

      final long = SpeechChunk.from(TextParser.parse(List.filled(100, 'kelime').join(' ')), 0);
      expect(long.end, SpeechChunk.maxTokens);
    });

    test('maps text offsets to token indexes', () {
      final chunk = SpeechChunk.from(TextParser.parse('Bir iki. Üç dört beş.'), 2);
      // "Üç dört beş.": Üç at 0, dört at 3, beş at 8
      expect(chunk.offsets, [0, 3, 8]);
      expect(chunk.indexAt(0), 2);
      expect(chunk.indexAt(2), 2);
      expect(chunk.indexAt(3), 3);
      expect(chunk.indexAt(9), 4);
      expect(chunk.indexAt(100), 4);
    });

    test('a chunk of only punctuation has nothing to say', () {
      expect(SpeechChunk.from(_dashThenWord, 0).isSpeakable, isFalse);
      expect(SpeechChunk.from(_dashThenWord, 1).isSpeakable, isTrue);
    });
  });

  test('speech rate labels', () {
    expect(speechRateLabel(1.0), '1x');
    expect(speechRateLabel(1.25), '1,25x');
    expect(speechRateLabel(0.5), '0,5x');
    expect(speechRateLabel(2.0), '2x');
  });

  test('flutter_tts rates: normal is 0.5 on mobile and 1.0 in browsers', () {
    expect(SpeechNarrator.platformRate(1.0, web: false), 0.5);
    expect(SpeechNarrator.platformRate(1.0, web: true), 1.0);
    expect(SpeechNarrator.platformRate(5.0, web: false), 1.0); // clamped to 2x
  });

  group('SpeechNarrator', () {
    testWidgets('speaks sentence by sentence and follows the word events', (tester) async {
      final tts = _FakeTts(tester);
      final narrator = SpeechNarrator();
      final words = <int>[];
      var done = false;

      narrator.speak(TextParser.parse('Bir iki. Üç dört beş.'), 0, onWord: words.add, onDone: () => done = true);
      await tester.pump();
      expect(tts.spoken, ['Bir iki.']);
      expect(words, [0]);

      await tts.send('speak.onStart');
      await tts.progress('Bir iki.', 4);
      expect(words.last, 1);

      await tts.finishSpeech();
      expect(tts.spoken, ['Bir iki.', 'Üç dört beş.']);
      expect(words.last, 2);

      await tts.progress('Üç dört beş.', 8);
      expect(words.last, 4);
      expect(done, isFalse);

      await tts.finishSpeech();
      expect(done, isTrue);
      expect(tts.calls, contains('setLanguage'));
      narrator.dispose();
    });

    testWidgets('after stop no more words are reported or spoken', (tester) async {
      final tts = _FakeTts(tester);
      final narrator = SpeechNarrator();
      final words = <int>[];
      var done = false;

      narrator.speak(TextParser.parse('Bir iki. Üç dört.'), 0, onWord: words.add, onDone: () => done = true);
      await tester.pump();
      narrator.stop();
      await tester.pump();
      expect(tts.calls, contains('stop'));

      await tts.progress('Bir iki.', 4);
      await tester.pump(const Duration(seconds: 1));
      expect(words, [0]);
      expect(tts.spoken, ['Bir iki.']);
      expect(done, isFalse);
    });

    testWidgets('a voice without word events is followed by time', (tester) async {
      final tts = _FakeTts(tester);
      final narrator = SpeechNarrator();
      final words = <int>[];

      narrator.speak(TextParser.parse('Bir iki üç dört beş altı.'), 0, onWord: words.add, onDone: () {});
      await tester.pump();
      await tts.send('speak.onStart');

      // 14 characters per second: after a second the voice is at "dört" (offset 11)
      await tester.pump(const Duration(milliseconds: 1040));
      expect(words.last, 3);
      await tester.pump(const Duration(seconds: 5));
      expect(words.last, 5); // never past the sentence

      narrator.stop();
      await tester.pump();
      await tts.finishSpeech();
    });

    testWidgets('skips parts with nothing to say', (tester) async {
      final tts = _FakeTts(tester);
      final narrator = SpeechNarrator();
      final words = <int>[];

      narrator.speak(_dashThenWord, 0, onWord: words.add, onDone: () {});
      await tester.pump();
      expect(tts.spoken, ['Kelime.']);
      expect(words, [1]);
      narrator.stop();
      await tester.pump();
    });

    testWidgets('reports whether a Turkish voice is available', (tester) async {
      final tts = _FakeTts(tester);
      expect(await SpeechNarrator().isAvailable(), isTrue);
      tts.available = false;
      expect(await SpeechNarrator().isAvailable(), isFalse);
    });
  });
}
