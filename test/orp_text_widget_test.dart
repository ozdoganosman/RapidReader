import 'package:flutter/material.dart';
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
}
