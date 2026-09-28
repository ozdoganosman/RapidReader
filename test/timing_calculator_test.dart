import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/utils/timing_calculator.dart';

int _duration(String word, {bool adaptive = false}) => TimingCalculator.calculateDuration(
      config: TimingConfig(baseWPM: 300, adaptiveSpeed: adaptive),
      word: word,
    );

void main() {
  test('a word takes 60000 / WPM milliseconds', () {
    expect(_duration('kitap'), 200);
  });

  test('a chunk is shown as long as its words together', () {
    expect(_duration('bir kitap'), 400);
    expect(_duration('bu bir kitap'), 600);
    // the average word length sets the adaptive factor, not the chunk
    // length, so a chunk takes about as long as its words one by one
    final separately = _duration('bir', adaptive: true) + _duration('kitap', adaptive: true);
    expect(_duration('bir kitap', adaptive: true), closeTo(separately, separately * 0.1));
  });

  test('a spaced dash is not counted as a word', () {
    expect(_duration('kitap —'), _duration('kitap') + 100); // + the dash pause
  });

  test('punctuation pauses stay', () {
    expect(_duration('kitap.'), 400);
    expect(_duration('bir kitap,'), 550);
  });

  test('no sentence pause after a period that is not a sentence end', () {
    const config = TimingConfig(baseWPM: 300, adaptiveSpeed: false);
    expect(TimingCalculator.calculateDuration(config: config, word: '19.', isSentenceEnd: false), 200);
    expect(TimingCalculator.calculateDuration(config: config, word: 'geldi.', isSentenceEnd: true), 400);
    expect(TimingCalculator.calculateDuration(config: config, word: 'geldi.'), 400);
  });
}
