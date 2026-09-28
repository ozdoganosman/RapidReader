import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/rsvp_engine.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';

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
}
