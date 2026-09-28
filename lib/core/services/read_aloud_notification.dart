/// Read Aloud Notification
///
/// The media notification and lock screen controls of the listening mode
/// (audio_service): play/pause and the previous/next paragraph. Its media
/// service also keeps the app running while it reads with the screen off,
/// so Android does not stop a long listening session.
library;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import 'read_aloud_player.dart';

class ReadAloudNotification extends BaseAudioHandler {
  static ReadAloudNotification? _instance;

  /// Start the media service, once at app start (Android and iOS)
  static Future<void> init() async {
    if (kIsWeb || _instance != null) return;
    try {
      _instance = await AudioService.init(
        builder: ReadAloudNotification.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.rapidreader.rapid_reader.read_aloud',
          androidNotificationChannelName: 'Sesli okuma',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      // Listening still works, without the notification
      debugPrint('Read-aloud notification unavailable: $e');
    }
  }

  /// The running handler; tests set one without the platform service
  @visibleForTesting
  static set instance(ReadAloudNotification? handler) => _instance = handler;

  /// Show [player] (reading [title]) in the notification; nothing when the
  /// service is not running (web, tests)
  static void attach(ReadAloudPlayer player, {required String title, String? album}) =>
      _instance?._attach(player, title, album);

  /// [player]'s screen was closed
  static void detach(ReadAloudPlayer player) => _instance?._detach(player);

  ReadAloudPlayer? _player;
  bool? _shownPlaying;

  void _attach(ReadAloudPlayer player, String title, String? album) {
    _player?.removeListener(_update);
    _player = player..addListener(_update);
    _shownPlaying = null;
    mediaItem.add(MediaItem(id: title, title: title, album: album, artist: 'RapidReader'));
    _update();
  }

  void _detach(ReadAloudPlayer player) {
    if (!identical(player, _player)) return;
    player.removeListener(_update);
    _player = null;
    playbackState.add(PlaybackState(processingState: AudioProcessingState.idle));
  }

  /// Update the notification when playing starts or stops (not on every
  /// word)
  void _update() {
    final player = _player;
    if (player == null || player.isPlaying == _shownPlaying) return;
    _shownPlaying = player.isPlaying;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        player.isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.skipToPrevious, MediaAction.skipToNext},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: player.isPlaying,
    ));
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> skipToNext() async {
    final player = _player;
    if (player != null) player.seek(player.paragraph + 1);
  }

  @override
  Future<void> skipToPrevious() async {
    final player = _player;
    if (player != null) player.seek(player.paragraph - 1);
  }

  @override
  Future<void> stop() async {
    _player?.pause();
    await super.stop();
  }
}
