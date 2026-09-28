import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/models/word_token.dart';
import 'package:rapid_reader/core/services/narrator.dart';
import 'package:rapid_reader/core/services/rsvp_engine.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';
import 'package:rapid_reader/core/utils/timing_calculator.dart';

void main() {
  // testWidgets runs in a fake-async zone, so engine timers can be advanced
  // deterministically with tester.pump(duration).

  testWidgets('completion keeps the index on the last word', (tester) async {
    final tokens = TextParser.parse('Bir iki üç dört.');
    final engine = RSVPEngine()..initialize(tokens: tokens);

    engine.play();
    await tester.pump(const Duration(seconds: 10));

    expect(engine.state.status, PlaybackStatus.completed);
    expect(engine.state.currentIndex, tokens.length - 1);
    expect(engine.state.currentToken, tokens.last);
    expect(engine.state.progress, 1.0);

    // Playing again restarts from the beginning
    engine.play();
    expect(engine.state.currentIndex, 0);
    engine.dispose();
  });

  test('seekToIndex lands exactly on the requested index', () {
    final tokens = TextParser.parse(List.generate(100, (i) => 'kelime$i').join(' '));
    final engine = RSVPEngine()..initialize(tokens: tokens);

    for (var i = 0; i < tokens.length; i++) {
      engine.seekToIndex(i);
      expect(engine.state.currentIndex, i);
    }

    engine.seekToIndex(500);
    expect(engine.state.currentIndex, tokens.length - 1);
    engine.seekToIndex(-5);
    expect(engine.state.currentIndex, 0);
    engine.dispose();
  });

  test('skipForward and skipBackward move by the exact word count', () {
    final tokens = TextParser.parse(List.generate(100, (i) => 'kelime$i').join(' '));
    final engine = RSVPEngine()..initialize(tokens: tokens, startIndex: 19);

    engine.skipForward(10);
    expect(engine.state.currentIndex, 29);
    engine.skipBackward(10);
    expect(engine.state.currentIndex, 19);
    engine.dispose();
  });

  testWidgets('pausing on a sentence end does not count it twice', (tester) async {
    final tokens = TextParser.parse('Bir. İki.');
    final engine = RSVPEngine()..initialize(tokens: tokens);

    engine.play();
    expect(engine.state.sentencesRead, 1);

    // Pause and resume on the same word several times
    for (var i = 0; i < 3; i++) {
      engine.pause();
      engine.play();
    }
    expect(engine.state.sentencesRead, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(engine.state.isComplete, isTrue);
    expect(engine.state.sentencesRead, 2);
    engine.dispose();
  });

  testWidgets('sentence count restarts after stop', (tester) async {
    final tokens = TextParser.parse('Bir. İki.');
    final engine = RSVPEngine()..initialize(tokens: tokens);

    engine.play();
    engine.stop();
    engine.play();
    expect(engine.state.sentencesRead, 1);
    engine.dispose();
  });

  group('speed warm-up', () {
    test('starts at 60% speed and reaches full speed after 20 words', () {
      const config = TimingConfig(baseWPM: 300, warmUp: true);
      expect(config.warmUpFactor(0), closeTo(1 / 0.6, 1e-9));
      expect(config.warmUpFactor(10), closeTo(1 / 0.8, 1e-9));
      expect(config.warmUpFactor(TimingConfig.warmUpWords), 1.0);
      expect(const TimingConfig(warmUp: false).warmUpFactor(0), 1.0);
    });

    testWidgets('the first words after play are shown longer', (tester) async {
      final tokens = TextParser.parse(List.filled(40, 'kelime').join(' '));
      Future<int> wordsAfter(bool warmUp, Duration time) async {
        final engine = RSVPEngine()
          ..initialize(tokens: tokens, config: TimingConfig(baseWPM: 300, adaptiveSpeed: false, warmUp: warmUp));
        engine.play();
        await tester.pump(time);
        final index = engine.state.currentIndex;
        engine.pause();
        engine.dispose();
        return index;
      }

      // 300 WPM = 200 ms per word: 10 words in 2 s without warm-up, fewer with it
      expect(await wordsAfter(false, const Duration(seconds: 2)), 10);
      expect(await wordsAfter(true, const Duration(seconds: 2)), lessThan(9));
    });
  });

  group('narrator', () {
    late _FakeNarrator narrator;
    late RSVPEngine engine;

    setUp(() {
      narrator = _FakeNarrator();
      engine = RSVPEngine()
        ..initialize(tokens: TextParser.parse('Bir iki üç dört beş altı.'))
        ..setNarrator(narrator);
    });

    tearDown(() => engine.dispose());

    test('play speaks from the current word and shows the spoken words', () {
      engine.seekToIndex(2);
      engine.play();
      expect(narrator.starts, [2]);

      narrator.onWord!(4);
      expect(engine.state.currentIndex, 4);
      expect(engine.state.currentToken?.word, 'beş');
      expect(engine.state.isPlaying, isTrue);

      narrator.onDone!();
      expect(engine.state.isComplete, isTrue);
      expect(engine.state.progress, 1.0);
    });

    test('pause stops the speech and ignores its late callbacks', () {
      engine.play();
      final lateWord = narrator.onWord!;
      engine.pause();
      expect(narrator.stops, greaterThan(0));

      lateWord(5);
      expect(engine.state.currentIndex, 0);
      expect(engine.state.status, PlaybackStatus.paused);
    });

    test('seeking while speaking restarts the speech at the new word', () {
      engine.play();
      final oldWord = narrator.onWord!;
      engine.skipForward(3);

      expect(narrator.starts, [0, 3]);
      expect(engine.state.isPlaying, isTrue);
      oldWord(1); // from the first speech: ignored
      expect(engine.state.currentIndex, 3);
    });

    test('removing the narrator pauses and returns to timed playback', () {
      engine.play();
      engine.setNarrator(null);
      expect(engine.state.isPlaying, isFalse);
      expect(engine.narrator, isNull);
      expect(narrator.stops, greaterThan(0));
    });
  });
}

class _FakeNarrator implements Narrator {
  final starts = <int>[];
  var stops = 0;
  void Function(int index)? onWord;
  void Function()? onDone;

  @override
  void speak(
    List<WordToken> tokens,
    int start, {
    required void Function(int index) onWord,
    required void Function() onDone,
  }) {
    starts.add(start);
    this.onWord = onWord;
    this.onDone = onDone;
  }

  @override
  void stop() => stops++;

  @override
  void dispose() {}
}
