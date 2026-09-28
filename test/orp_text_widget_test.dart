import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/presentation/widgets/orp_text_widget.dart';

/// Pump an [RSVPDisplay] filling the default 800x600 test surface.
Future<void> _pumpDisplay(
  WidgetTester tester,
  String word, {
  double fontSize = 32,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RSVPDisplay(
          word: word,
          fontSize: fontSize,
          // Non-mono family keeps the test offline (no Google Fonts fetch)
          fontFamily: 'sans',
        ),
      ),
    ),
  );
}

void main() {
  _themedTests();
  _rightToLeftTests();

  const screenCenter = 400.0;

  final focusGuide = find.byWidgetPredicate(
    (w) => w is Container && w.constraints == const BoxConstraints.tightFor(width: 2, height: 24),
  );

  group('ORP character stays on the focus line', () {
    for (final (word, orp) in [
      ('kitap', 'i'),
      ("Türkiye'nin", 'k'),
      ('ve', 'v'),
      ('merhaba,', 'r'),
    ]) {
      testWidgets('for "$word"', (tester) async {
        await _pumpDisplay(tester, word);

        expect(tester.getCenter(find.text(orp)).dx, moreOrLessEquals(screenCenter, epsilon: 0.5));
        for (final guide in focusGuide.evaluate()) {
          expect(tester.getCenter(find.byWidget(guide.widget)).dx, moreOrLessEquals(screenCenter, epsilon: 0.5));
        }
      });
    }
  });

  testWidgets('long words shrink to fit instead of overflowing', (tester) async {
    await _pumpDisplay(tester, 'Çekoslovakyalılaştıramadıklarımızdanmışsınız', fontSize: 60);

    expect(tester.takeException(), isNull);
    expect(tester.getCenter(find.text('s')).dx, moreOrLessEquals(screenCenter, epsilon: 0.5));
  });

  testWidgets('system text scaling keeps the word centered', (tester) async {
    await _pumpDisplay(tester, 'kitap', textScale: 2);

    expect(tester.takeException(), isNull);
    expect(tester.getCenter(find.text('i')).dx, moreOrLessEquals(screenCenter, epsilon: 0.5));
  });

  testWidgets('the dyslexia font keeps the focus letter centered', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: RSVPDisplay(word: 'kitap', fontSize: 32, fontFamily: 'OpenDyslexic'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final orp = tester.widget<Text>(find.text('i'));
    expect(orp.style?.fontFamily, 'OpenDyslexic');
    expect(tester.getCenter(find.text('i')).dx, moreOrLessEquals(screenCenter, epsilon: 0.5));
  });
}

/// Whether every part of the shown word fits its box (nothing wraps away
/// or is cut off)
bool _allPartsFit(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(find.descendant(of: find.byType(ORPTextWidget), matching: find.byType(RichText)))
    .every((paragraph) => paragraph.getMaxIntrinsicWidth(double.infinity) <= paragraph.size.width + 0.01);

void _rightToLeftTests() {
  testWidgets('an Arabic word is shown whole, not split into parts', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RSVPDisplay(word: '(العلق)', fontFamily: 'sans')),
    ));
    expect(find.text('(العلق)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _themedTests() {
  // In the app the text inherits the theme's text style (Material 3 body
  // text has letter spacing); the parts must still fit their boxes
  for (final word in ['huzursuz düşlerden', 'uyandığında, kendini', 'Birinci', 'bir sabah uyandı']) {
    testWidgets('"$word" fits inside the app theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RSVPDisplay(word: word, fontFamily: 'sans')),
      ));
      expect(_allPartsFit(tester), isTrue);
    });
  }
}
