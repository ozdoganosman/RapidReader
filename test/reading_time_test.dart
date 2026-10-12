import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/daily_reminder.dart';
import 'package:rapid_reader/core/services/reading_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  var clock = DateTime(2026, 10, 12, 9);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 10, 12, 9);
    ReadingTime.now = () => clock;
    ReadingTime.onFirstReadToday = null;
  });

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('reading adds up for today and starts again the next day', () async {
    var firstReads = 0;
    ReadingTime.onFirstReadToday = () => firstReads++;

    expect(await ReadingTime.add(120, goalMinutes: 5), isFalse);
    expect(await ReadingTime.add(200, goalMinutes: 5), isTrue, reason: 'the goal (300 s) is crossed now');
    expect(await ReadingTime.add(60, goalMinutes: 5), isFalse, reason: 'only the once a day');
    expect(await ReadingTime.load(), 380);
    expect(firstReads, 1);

    clock = DateTime(2026, 10, 13, 8);
    expect(await ReadingTime.load(), 0);
    await ReadingTime.add(30, goalMinutes: 0);
    expect(ReadingTime.today.value, 30);
    expect(firstReads, 2);
  });

  test('no goal is never reached', () async {
    expect(await ReadingTime.add(3600, goalMinutes: 0), isFalse);
  });

  test('the clock counts the time between start and stop', () async {
    var reached = 0;
    final readingClock = ReadingClock(goalMinutes: () => 1, onGoalReached: () => reached++);
    readingClock.start();
    clock = clock.add(const Duration(seconds: 70));
    readingClock.stop();
    await settle();
    expect(await ReadingTime.load(), 70);
    expect(reached, 1);
  });

  test('an idle page counts only up to the idle limit', () async {
    final readingClock = ReadingClock(goalMinutes: () => 10, idleLimit: const Duration(minutes: 3));
    readingClock.start();
    clock = clock.add(const Duration(minutes: 20));
    readingClock.stop();
    await settle();
    expect(await ReadingTime.load(), 180);
  });

  test('the reminder is today if still ahead, else tomorrow', () {
    final morning = DateTime(2026, 10, 12, 9);
    expect(DailyReminder.nextTime(morning, 20, 0), DateTime(2026, 10, 12, 20));
    expect(DailyReminder.nextTime(morning, 20, 0, skipToday: true), DateTime(2026, 10, 13, 20));
    expect(DailyReminder.nextTime(DateTime(2026, 10, 12, 21), 20, 0), DateTime(2026, 10, 13, 20));
    expect(DailyReminder.nextTime(DateTime(2026, 12, 31, 21), 20, 30), DateTime(2027, 1, 1, 20, 30));
  });
}
