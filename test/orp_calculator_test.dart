import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/utils/orp_calculator.dart';

String _orp(String word) => ORPCalculator.splitForDisplay(word).toString();

void main() {
  group('ORPCalculator.splitForDisplay', () {
    test('plain words', () {
      expect(_orp('kitap'), 'k[i]tap');
      expect(_orp('ve'), 'v[e]');
      expect(_orp('o'), '[o]');
      expect(_orp("Türkiye'nin"), "Tür[k]iye'nin");
    });

    test('never lands on an apostrophe or hyphen', () {
      expect(_orp("O'na"), "O'[n]a");
      expect(_orp("o'nun"), "o'[n]un");
      expect(_orp('a-bcd'), 'a-[b]cd');
      expect(_orp('e-posta'), 'e-p[o]sta');
    });

    test('skips surrounding quotes, brackets and dashes', () {
      expect(_orp('"Merhaba"'), '"Me[r]haba"');
      expect(_orp('(kitap).'), '(k[i]tap).');
      expect(_orp('— Merhaba,'), '— Me[r]haba,');
      expect(_orp('bir —'), 'b[i]r —');
    });

    test('never lands on the space inside a chunk', () {
      expect(_orp('bir iki'), 'bi[r] iki');
      for (final chunk in ['ve bu', 'a b c', 'o bir iki', "O'na da"]) {
        expect(ORPCalculator.splitForDisplay(chunk).orp, isNot(anyOf(' ', "'", '-')));
      }
    });

    test('punctuation-only tokens do not crash', () {
      expect(_orp('...'), '[.]..');
      expect(_orp('"'), '["]');
    });
  });
}
