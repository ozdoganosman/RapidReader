import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/utils/orp_calculator.dart';

String _orp(String word) => ORPCalculator.splitForDisplay(word).toString();

void main() {
  group('ORPCalculator.splitForDisplay', () {
    test('plain words follow the length table', () {
      expect(_orp('o'), '[o]');
      expect(_orp('ve'), '[v]e');
      expect(_orp('kitap'), 'k[i]tap');
      expect(_orp('okuyorum'), 'ok[u]yorum');
      expect(_orp("Türkiye'nin"), "Tür[k]iye'nin");
    });

    test('never lands on an apostrophe or hyphen', () {
      expect(_orp("O'na"), "O'[n]a");
      expect(_orp("o'nun"), "o'[n]un");
      expect(_orp('a-bcd'), 'a-[b]cd');
      expect(_orp('e-posta'), 'e-p[o]sta');
    });

    test('surrounding punctuation does not shift the ORP', () {
      expect(_orp('kitap.'), _orp('kitap').replaceFirst('tap', 'tap.'));
      expect(_orp('"Merhaba"'), '"Me[r]haba"');
      expect(_orp('(kitap).'), '(k[i]tap).');
      expect(_orp('«Evet»'), '«E[v]et»');
    });

    test('chunks use the middle word', () {
      expect(_orp('bir iki'), 'bir i[k]i');
      expect(_orp('bu bir kitap'), 'bu b[i]r kitap');
      expect(_orp("ve O'na"), "ve O'[n]a");
    });

    test('punctuation-only tokens do not crash', () {
      expect(_orp('...'), '[.]..');
      expect(_orp('"'), '["]');
      expect(_orp('—'), '[—]');
    });
  });
}
