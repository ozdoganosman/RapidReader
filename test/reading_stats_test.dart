import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/reading_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final today = DateTime(2026, 9, 28, 20);
  DateTime daysAgo(int n) => DateTime(2026, 9, 28 - n, 12);

  test('adds sessions per day and computes totals', () async {
    await ReadingStats.addReading(words: 600, time: const Duration(minutes: 2), now: today);
    await ReadingStats.addReading(words: 300, time: const Duration(minutes: 1), now: today);
    await ReadingStats.addReading(words: 5, time: const Duration(seconds: 1), now: today); // too short

    final stats = await ReadingStats.load(now: today);
    expect(stats.today.words, 900);
    expect(stats.today.minutes, 3);
    expect(stats.totalWords, 900);
    expect(stats.averageWordsPerMinute, 300);
    expect(stats.lastWeek, hasLength(7));
    expect(stats.lastWeek.last.words, 900);
  });

  test('streak counts days in a row that met the goal', () async {
    await ReadingStats.setGoalMinutes(5);
    for (final n in [1, 2, 3, 5]) {
      await ReadingStats.addReading(words: 1000, time: const Duration(minutes: 6), now: daysAgo(n));
    }
    await ReadingStats.addReading(words: 100, time: const Duration(minutes: 2), now: daysAgo(4)); // under the goal

    // Today's goal not met yet: the streak runs through yesterday
    var stats = await ReadingStats.load(now: today);
    expect(stats.streak, 3);
    expect(stats.goalMetToday, isFalse);

    await ReadingStats.addReading(words: 1000, time: const Duration(minutes: 5), now: today);
    stats = await ReadingStats.load(now: today);
    expect(stats.streak, 4);
    expect(stats.goalMetToday, isTrue);
  });

  test('keeps speed test results, newest first', () async {
    await ReadingStats.addSpeedTest(SpeedTestResult(date: daysAgo(2), testId: 't1', wordsPerMinute: 220, comprehension: 75));
    await ReadingStats.addSpeedTest(SpeedTestResult(date: daysAgo(1), testId: 't2', wordsPerMinute: 260, comprehension: 100));

    final stats = await ReadingStats.load(now: today);
    expect(stats.speedTests.map((r) => r.testId), ['t2', 't1']);
    expect(stats.speedTests.last.effectiveWordsPerMinute, 165);
  });
}
