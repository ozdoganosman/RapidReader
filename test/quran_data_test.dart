import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/data/quran.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic text: every surah file has the right number of verses', () async {
    const verseCounts = {1: 7, 2: 286, 9: 129, 96: 19, 114: 6};
    for (final entry in verseCounts.entries) {
      expect(await loadArabicSurah(entry.key), hasLength(entry.value), reason: 'surah ${entry.key}');
    }
    expect(quranRevelationOrder.toSet(), hasLength(114));
    expect(normalizeForSearch("Âl-i İmran"), 'al-i imran');
  });
}
