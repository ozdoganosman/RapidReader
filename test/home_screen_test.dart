import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rapid_reader/core/services/custom_book_service.dart';
import 'package:rapid_reader/main.dart';
import 'package:rapid_reader/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The field of the add-text dialog with [label]
Finder _field(String label) => find.widgetWithText(TextField, label);

void main() {
  setUp(() {
    // An in-memory box (file IO would not complete in the fake async zone)
    // whose saves take a moment, as on a device
    CustomBookService.initStorage = () async {};
    CustomBookService.openHiveBox = (name) async => _SlowBox(await Hive.openBox<String>(name, bytes: Uint8List(0)));
    SharedPreferences.setMockInitialValues({});
    // Cached asset futures belong to the previous test's fake async zone
    rootBundle.clear();
  });

  Future<void> pumpApp(WidgetTester tester, {Size size = const Size(800, 1600)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'plugins.flutter.io/google_mobile_ads',
      (message) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('receive_sharing_intent/messages'),
      (call) async => null,
    );
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('receive_sharing_intent/events-media'),
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );

    await tester.pumpWidget(const RapidReaderApp());
    await settle(tester, () => find.text('Metin Ekle').evaluate().isNotEmpty);
  }

  testWidgets('the library fits a small phone with larger system text', (tester) async {
    // Real Roboto widths (the test font's glyphs are squares, twice as wide)
    if (await tester.runAsync(_loadRoboto) != true) {
      markTestSkipped('Roboto from the Flutter SDK not found');
      return;
    }
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull); // no overflow
    expect(find.text('Kitaplık'), findsOneWidget);
    await CustomBookService.reset();
  });

  testWidgets('empty required fields are marked in the dialog', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Metin Ekle'));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Kaydetmeden Oku'));
    await tester.pump();
    expect(find.text('Metin gerekli'), findsOneWidget);
    expect(find.text('Başlık gerekli'), findsNothing); // not needed to just read

    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    expect(find.text('Başlık gerekli'), findsOneWidget);

    await tester.enterText(_field('Başlık gerekli'), 'Deneme');
    await tester.pump();
    expect(find.text('Başlık gerekli'), findsNothing);
    await CustomBookService.reset();
  });

  testWidgets('tapping "Kaydet" twice saves the text once and keeps the library', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Metin Ekle'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(_field('Başlık *'), 'Deneme');
    await tester.enterText(_field('Metin İçeriği *'), 'Bir iki üç.');

    await tester.tap(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await settle(tester, () => find.text('Metin başarıyla eklendi!').evaluate().isNotEmpty);

    final books = await CustomBookService.loadCustomBooks();
    expect(books.map((b) => b.title), ['Deneme']);
    expect(find.byType(HomeScreen), findsOneWidget);

    // Close the box here: it belongs to the test's fake async zone, and
    // closing it from tearDown never completes
    await CustomBookService.reset();
  });
}

/// Pump (letting real async work such as Hive and asset loading run) until
/// [done] or about 10 seconds have passed
Future<void> settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
}

/// A box whose writes take half a second
class _SlowBox implements Box<String> {
  final Box<String> _inner;

  _SlowBox(this._inner);

  static const _delay = Duration(milliseconds: 500);

  @override
  Future<int> add(String value) async {
    await Future<void>.delayed(_delay);
    return _inner.add(value);
  }

  @override
  Future<void> delete(dynamic key) async {
    await Future<void>.delayed(_delay);
    return _inner.delete(key);
  }

  @override
  Future<void> put(dynamic key, String value) => _inner.put(key, value);

  @override
  Iterable<String> get values => _inner.values;

  @override
  Iterable<dynamic> get keys => _inner.keys;

  @override
  String? get(dynamic key, {String? defaultValue}) => _inner.get(key, defaultValue: defaultValue);

  @override
  Future<void> close() => _inner.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

/// Load Roboto (as the theme's family) from the Flutter SDK's font cache;
/// false if it is not there
Future<bool> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final loader = FontLoader('Roboto');
  for (final weight in ['Light', 'Regular', 'Medium', 'Bold']) {
    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf');
    if (!file.existsSync()) return false;
    final bytes = await file.readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  return true;
}
