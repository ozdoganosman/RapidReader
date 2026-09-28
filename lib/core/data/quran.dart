/// Quran data helpers
///
/// The bundled meal (`assets/books/Kuran_<n>.txt`) is numbered in order of
/// revelation; the Arabic text (`assets/quran/ar_<n>.txt`, Tanzil Project,
/// used verbatim) is numbered in mushaf order.
library;

import 'package:flutter/services.dart';

/// Bundled Arabic font (Amiri Quran, SIL OFL 1.1), also the fallback for
/// Arabic words in other text, so they render on web and offline
const quranArabicFont = 'AmiriQuran';

/// Series name of the bundled meal
const quranSeriesName = 'Kuran';

/// Mushaf (surah) number of each surah in order of revelation:
/// quranRevelationOrder[0] is the first revealed surah (al-Alaq, 96)
const quranRevelationOrder = <int>[
  96, 68, 73, 74, 1, 111, 81, 87, 92, 89,
  93, 94, 103, 100, 108, 102, 107, 109, 105, 113,
  114, 112, 53, 80, 97, 91, 85, 95, 106, 101,
  75, 104, 77, 50, 90, 86, 54, 38, 7, 72,
  36, 25, 35, 19, 20, 56, 26, 27, 28, 17,
  10, 11, 12, 15, 6, 37, 31, 34, 39, 40,
  41, 42, 43, 44, 45, 46, 51, 88, 18, 16,
  71, 14, 21, 23, 32, 52, 67, 69, 70, 78,
  79, 82, 84, 30, 29, 83, 2, 8, 3, 33,
  60, 4, 99, 57, 47, 13, 55, 76, 65, 98,
  59, 24, 22, 63, 58, 49, 66, 64, 61, 62,
  48, 5, 9, 110,
];

/// Mushaf number of the surah that is [revelationNumber]th in order of revelation (1-based)
int quranMushafNumber(int revelationNumber) => quranRevelationOrder[revelationNumber - 1];

/// Whether surah [mushafNumber] starts with the basmala as a heading
/// (al-Fatiha has it as its first verse, at-Tawba has none)
bool quranHasBasmalaHeading(int mushafNumber) => mushafNumber != 1 && mushafNumber != 9;

const quranBasmala = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

/// Where the Arabic text comes from (its license asks for this)
const quranArabicSource = 'Arapça metin: Tanzil Projesi (tanzil.net), değiştirilmeden kullanılmıştır. CC BY 3.0';

/// The Arabic verses of surah [mushafNumber]
Future<List<String>> loadArabicSurah(int mushafNumber) async {
  final text = await rootBundle.loadString('assets/quran/ar_$mushafNumber.txt');
  return text.split('\n').where((line) => line.trim().isNotEmpty).toList();
}

/// Verse number in Arabic-Indic digits, e.g. 12 -> "١٢"
String arabicDigits(int number) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return number.toString().split('').map((d) => digits[int.parse(d)]).join();
}

/// Lowercase text without Turkish circumflexes and apostrophes, for search
/// ("Âl-i İmran" and "al-i imran" match)
String normalizeForSearch(String text) {
  final lower = text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  return lower
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp("['’`]"), '')
      .replaceAll('ı', 'i');
}
