import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('flutter_tts');
const _codec = StandardMethodCodec();

/// The platform side of flutter_tts: records the calls; in one-at-a-time
/// mode each speech finishes when the test completes it
class FakeTts {
  final WidgetTester tester;
  final calls = <MethodCall>[];
  Completer<int>? _speech;
  bool available = true;

  FakeTts(this.tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isLanguageAvailable':
          return available;
        case 'speak':
          if (_awaitsCompletion) {
            _speech = Completer<int>();
            return _speech!.future;
          }
          return 1;
        case 'stop':
          _speech?.complete(0);
          _speech = null;
          return 1;
      }
      return 1;
    });
  }

  bool get _awaitsCompletion =>
      calls.lastWhere((c) => c.method == 'awaitSpeakCompletion', orElse: () => const MethodCall('')).arguments == true;

  List<String> get spoken => [
        for (final c in calls)
          if (c.method == 'speak') c.arguments as String
      ];

  List<Object?> arguments(String method) => [
        for (final c in calls)
          if (c.method == method) c.arguments
      ];

  Future<void> send(String method, [Object? arguments]) async {
    await tester.binding.defaultBinaryMessenger
        .handlePlatformMessage(_channel.name, _codec.encodeMethodCall(MethodCall(method, arguments)), (_) {});
    await tester.pump();
  }

  Future<void> start() => send('speak.onStart');

  Future<void> complete() => send('speak.onComplete');

  Future<void> progress(String text, int start, int end) =>
      send('speak.onProgress', {'text': text, 'start': '$start', 'end': '$end', 'word': text.substring(start, end)});

  /// Finish the speech of the one-at-a-time mode
  Future<void> finishSpeech() async {
    _speech?.complete(1);
    _speech = null;
    await tester.pump();
  }
}
