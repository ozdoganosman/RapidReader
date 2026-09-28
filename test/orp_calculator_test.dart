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

    test('chunks are focused on the letter nearest their middle', () {
      expect(_orp('bir iki'), 'bi[r] iki');
      expect(_orp('bu bir kitap'), 'bu bi[r] kitap');
      expect(_orp('huzursuz düşlerden'), 'huzursu[z] düşlerden');
      expect(_orp('uyandığında, kendini'), 'uyandığın[d]a, kendini');
      // never on a space, apostrophe or punctuation, nor on the first letter
      // of a later word (the space before it would not be drawn)
      expect(_orp("ve O'na"), "v[e] O'na");
      expect(_orp('Gregor Samsa bir'), 'Gregor S[a]msa bir');
      expect(_orp('ah! ne'), 'a[h]! ne');
    });

    test('the part before the ORP of a chunk never ends with a space', () {
      const text = 'Gregor Samsa bir sabah huzursuz düşlerden uyandığında o bu ve';
      final words = text.split(' ');
      for (var size = 2; size <= 3; size++) {
        for (var i = 0; i + size <= words.length; i++) {
          final parts = ORPCalculator.splitForDisplay(words.sublist(i, i + size).join(' '));
          expect(parts.before.endsWith(' '), isFalse, reason: parts.toString());
          expect(parts.orp, isNot(' '));
        }
      }
    });

    test('a word with a spaced dash keeps the word\'s own ORP', () {
      expect(_orp('kelime —'), 'ke[l]ime —');
      expect(_orp('— kitap'), '— k[i]tap');
    });

    test('only letters and digits can be the ORP', () {
      expect(_orp('3.5'), '[3].5');
      expect(_orp('1.000'), '1.[0]00');
      expect(_orp('...Artık'), '...A[r]tık');
      expect(_orp('•Birinci'), '•Bi[r]inci');
      expect(_orp('ka\u00ADlem'), 'k[a]\u00ADlem'); // soft hyphen
    });

    test('an emoji or a letter with a combining mark stays whole', () {
      expect(_orp('😀'), '[😀]');
      expect(_orp('gu\u0308l'), 'g[u\u0308]l'); // "gül" in decomposed form
    });

    test('punctuation-only tokens do not crash', () {
      expect(_orp('...'), '[.]..');
      expect(_orp('"'), '["]');
      expect(_orp('—'), '[—]');
    });
  });
}
