import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/read_aloud_notification.dart';
import 'package:rapid_reader/core/services/read_aloud_player.dart';

import 'helpers/fake_tts.dart';

void main() {
  tearDown(() => ReadAloudNotification.instance = null);

  testWidgets('the notification shows the reading and its buttons control it', (tester) async {
    final tts = FakeTts(tester);
    final handler = ReadAloudNotification();
    ReadAloudNotification.instance = handler;
    final player = ReadAloudPlayer(paragraphs: const ['Bir.', 'İki.', 'Üç.'], queue: true);

    ReadAloudNotification.attach(player, title: 'Dönüşüm - Birinci Bölüm', album: 'Franz Kafka');
    expect(handler.mediaItem.value?.title, 'Dönüşüm - Birinci Bölüm');
    expect(handler.playbackState.value.playing, isFalse);

    await handler.play();
    await tester.pump();
    expect(player.isPlaying, isTrue);
    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.playbackState.value.controls, contains(MediaControl.pause));

    await handler.skipToNext();
    await tester.pump();
    expect(player.paragraph, 1);
    expect(tts.spoken.last, 'Üç.');

    await handler.pause();
    await tester.pump();
    expect(player.isPlaying, isFalse);
    expect(handler.playbackState.value.controls, contains(MediaControl.play));

    ReadAloudNotification.detach(player);
    expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
    player.dispose();
  });
}
