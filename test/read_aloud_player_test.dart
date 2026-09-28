import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/read_aloud_player.dart';

import 'helpers/fake_tts.dart';

void main() {
  const paragraphs = ['Birinci paragraf burada.', 'İkinci paragraf.', 'Üçüncü ve son paragraf.'];

  test('speech rate labels', () {
    expect(speechRateLabel(1.0), '1x');
    expect(speechRateLabel(1.25), '1,25x');
    expect(speechRateLabel(0.5), '0,5x');
  });

  test('flutter_tts rates: normal is 0.5 on mobile and 1.0 in browsers', () {
    expect(ReadAloudPlayer.platformRate(1.0, web: false), 0.5);
    expect(ReadAloudPlayer.platformRate(1.0, web: true), 1.0);
    expect(ReadAloudPlayer.platformRate(5.0, web: false), 1.0); // at most 2x
  });

  group('queued (Android, iOS)', () {
    testWidgets('queues all paragraphs at once, with no gap between them', (tester) async {
      final tts = FakeTts(tester);
      final player = ReadAloudPlayer(paragraphs: paragraphs, queue: true);

      await player.play();
      await tester.pump();
      expect(tts.spoken, paragraphs);
      expect(tts.arguments('setQueueMode'), [1]);
      expect(tts.arguments('awaitSpeakCompletion'), [false]);
      expect(tts.arguments('setLanguage'), ['tr-TR']);
      expect(player.isPlaying, isTrue);
      player.dispose();
    });

    testWidgets('follows the voice: word events and finished paragraphs', (tester) async {
      final tts = FakeTts(tester);
      var finished = false;
      final player = ReadAloudPlayer(paragraphs: paragraphs, queue: true)..onFinished = () => finished = true;
      await player.play();
      await tester.pump();

      await tts.start();
      await tts.progress(paragraphs[0], 8, 17); // "paragraf"
      expect(player.paragraph, 0);
      expect([player.wordStart, player.wordEnd], [8, 17]);

      await tts.complete();
      expect(player.paragraph, 1);
      expect(player.wordStart, isNull);

      // A word event of a later utterance also moves on
      await tts.progress(paragraphs[2], 0, 6);
      expect(player.paragraph, 2);

      await tts.complete();
      expect(finished, isTrue);
      expect(player.isPlaying, isFalse);
      player.dispose();
    });

    testWidgets('pausing and playing again goes on from the word being read', (tester) async {
      final tts = FakeTts(tester);
      final player = ReadAloudPlayer(paragraphs: paragraphs, queue: true);
      await player.play();
      await tester.pump();
      await tts.start();
      await tts.progress(paragraphs[0], 8, 17);

      player.pause();
      await tester.pump();
      expect(tts.arguments('stop'), hasLength(1));
      expect(player.isPlaying, isFalse);

      // A completion of the stopped queue does not move the position
      await tts.complete();
      expect(player.paragraph, 0);

      tts.calls.clear();
      await player.play();
      await tester.pump();
      expect(tts.spoken, ['paragraf burada.', paragraphs[1], paragraphs[2]]);

      // Word offsets are still in the whole paragraph
      await tts.start();
      await tts.progress('paragraf burada.', 9, 15); // "burada"
      expect([player.wordStart, player.wordEnd], [17, 23]);
      player.dispose();
    });

    testWidgets('a new speed restarts the queue at the current word', (tester) async {
      final tts = FakeTts(tester);
      final player = ReadAloudPlayer(paragraphs: paragraphs, queue: true);
      await player.play();
      await tester.pump();
      await tts.start();
      await tts.complete(); // on paragraph 2

      tts.calls.clear();
      player.setRate(1.5);
      await tester.pump();
      expect(tts.arguments('stop'), hasLength(1));
      expect(tts.arguments('setSpeechRate'), [0.75]);
      expect(tts.spoken, paragraphs.sublist(1));
      player.dispose();
    });

    testWidgets('a long paragraph is cut at a sentence end', (tester) async {
      final tts = FakeTts(tester);
      final sentence = '${List.filled(30, 'kelime').join(' ')}. ';
      final long = sentence * 30; // about 6000 characters
      final player = ReadAloudPlayer(paragraphs: [long.trim()], queue: true);
      await player.play();
      await tester.pump();

      expect(tts.spoken.length, greaterThan(1));
      for (final piece in tts.spoken) {
        expect(piece.length, lessThanOrEqualTo(ReadAloudPlayer.maxUtteranceLength));
        expect(piece, endsWith('.'));
      }
      expect(tts.spoken.join(' '), long.trim());
      player.dispose();
    });

    testWidgets('reports a missing Turkish voice', (tester) async {
      final tts = FakeTts(tester)..available = false;
      expect(await ReadAloudPlayer(paragraphs: paragraphs, queue: true).isAvailable(), isFalse);
      tts.available = true;
      expect(await ReadAloudPlayer(paragraphs: paragraphs, queue: true).isAvailable(), isTrue);
    });
  });

  testWidgets('one at a time (browsers): the next paragraph after the speech ends', (tester) async {
    final tts = FakeTts(tester);
    final player = ReadAloudPlayer(paragraphs: paragraphs, queue: false);
    unawaited(player.play());
    await tester.pump();
    expect(tts.arguments('awaitSpeakCompletion'), [true]);
    expect(tts.spoken, [paragraphs[0]]);

    await tts.finishSpeech();
    expect(tts.spoken, paragraphs.sublist(0, 2));
    expect(player.paragraph, 1);

    player.pause();
    await tester.pump();
    expect(player.isPlaying, isFalse);
    player.dispose();
  });
}
