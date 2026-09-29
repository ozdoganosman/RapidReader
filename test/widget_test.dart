import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/app_language.dart';
import 'package:rapid_reader/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answer the calls of the plugins the library screen uses
void _mockPlugins(WidgetTester tester) {
  // The banner ad talks to the native AdMob plugin; answer its calls
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'plugins.flutter.io/google_mobile_ads',
    (message) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
  // Android "Share" plugin: nothing shared
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('receive_sharing_intent/messages'),
    (call) async => null,
  );
  tester.binding.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('receive_sharing_intent/events-media'),
    MockStreamHandler.inline(onListen: (arguments, events) {}),
  );
}

/// Pump until the library (the [text] of one of its books) is shown
Future<void> _waitFor(WidgetTester tester, String text) async {
  for (var i = 0; i < 50 && find.text(text).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

void main() {
  setUp(() => rootBundle.clear());

  for (final (device, library, book) in [
    (const Locale('tr', 'TR'), 'Kitaplık', 'İki Şehrin Hikâyesi'),
    (const Locale('en', 'US'), 'Library', 'A Tale of Two Cities'),
    (const Locale('hi', 'IN'), 'Library', 'A Tale of Two Cities'),
  ]) {
    testWidgets('on a $device device the app and its library are in ${library == 'Library' ? 'English' : 'Turkish'}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      _mockPlugins(tester);
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const RapidReaderApp());
      await _waitFor(tester, book);
      expect(find.text(library), findsOneWidget);
      expect(find.text(book), findsOneWidget);
    });
  }

  testWidgets('the language chosen in the settings wins over the device', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _mockPlugins(tester);
    tester.platformDispatcher.localesTestValue = [const Locale('tr', 'TR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    AppLanguage.choice.value = 'en';
    addTearDown(() => AppLanguage.choice.value = null);

    await tester.pumpWidget(const RapidReaderApp());
    await _waitFor(tester, 'A Tale of Two Cities');
    expect(find.text('Library'), findsOneWidget);

    AppLanguage.choice.value = 'tr';
    await tester.pump();
    await _waitFor(tester, 'İki Şehrin Hikâyesi');
    expect(find.text('Kitaplık'), findsOneWidget);
  });

  testWidgets('App launches and shows the library', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // The banner ad talks to the native AdMob plugin; answer its calls
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );

    // Android "Share" plugin: nothing shared
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('receive_sharing_intent/messages'),
      (call) async => null,
    );
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('receive_sharing_intent/events-media'),
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );

    // Build the app
    await tester.pumpWidget(const RapidReaderApp());

    // Books are loaded from the asset bundle in the background
    for (var i = 0; i < 50 && find.text('RapidReader').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }

    // Verify the app title is present once the library is shown
    expect(find.text('RapidReader'), findsOneWidget);
  });
}
