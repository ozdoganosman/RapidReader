import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answer wakelock_plus platform calls (its pigeon channel) with success
void mockWakelock(WidgetTester tester) {
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );
}
