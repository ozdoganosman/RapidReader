/// Reading Stats
///
/// Reading time and words per day, the daily goal, the streak of days the
/// goal was met, and the results of the reading speed test. Everything is
/// kept on the device (shared_preferences).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Words and seconds read on one day
class DayStats {
  final DateTime day;
  final int words;
  final int seconds;

  const DayStats(this.day, {this.words = 0, this.seconds = 0});

  int get minutes => seconds ~/ 60;
}

/// Result of one reading speed test
class SpeedTestResult {
  final DateTime date;
  final String testId;

  /// Words per minute while reading normally
  final int wordsPerMinute;

  /// Share of questions answered correctly, 0–100
  final int comprehension;

  const SpeedTestResult({
    required this.date,
    required this.testId,
    required this.wordsPerMinute,
    required this.comprehension,
  });

  /// Words understood per minute
  int get effectiveWordsPerMinute => wordsPerMinute * comprehension ~/ 100;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'testId': testId,
        'wpm': wordsPerMinute,
        'comprehension': comprehension,
      };

  factory SpeedTestResult.fromJson(Map<String, dynamic> json) => SpeedTestResult(
        date: DateTime.parse(json['date'] as String),
        testId: json['testId'] as String,
        wordsPerMinute: json['wpm'] as int,
        comprehension: json['comprehension'] as int,
      );
}

/// Everything the stats screen shows
class StatsSummary {
  /// Daily goal in minutes
  final int goalMinutes;

  final DayStats today;

  /// The last 7 days, oldest first, today last
  final List<DayStats> lastWeek;

  /// Days in a row the goal was met, ending today (or yesterday if today's
  /// goal is not met yet)
  final int streak;

  final int totalWords;
  final int totalSeconds;

  /// Speed test results, newest first
  final List<SpeedTestResult> speedTests;

  const StatsSummary({
    required this.goalMinutes,
    required this.today,
    required this.lastWeek,
    required this.streak,
    required this.totalWords,
    required this.totalSeconds,
    required this.speedTests,
  });

  bool get goalMetToday => today.seconds >= goalMinutes * 60;

  /// Average speed over all reading, 0 if nothing was read yet
  int get averageWordsPerMinute => totalSeconds < 60 ? 0 : totalWords * 60 ~/ totalSeconds;
}

class ReadingStats {
  static const _key = 'reading_stats';

  static const defaultGoalMinutes = 10;
  static const goalChoices = [5, 10, 15, 20, 30];

  /// Sessions shorter than this are not counted (a tap and pause)
  static const minSessionSeconds = 2;

  static String _dayKey(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

  static Future<Map<String, dynamic>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Add a reading session that ended at [now]
  static Future<void> addReading({required int words, required Duration time, DateTime? now}) async {
    if (words <= 0 || time.inSeconds < minSessionSeconds) return;
    final data = await _read();
    final days = (data['days'] as Map<String, dynamic>?) ?? {};
    final key = _dayKey(now ?? DateTime.now());
    final day = (days[key] as Map<String, dynamic>?) ?? {};
    days[key] = {
      'words': ((day['words'] as int?) ?? 0) + words,
      'seconds': ((day['seconds'] as int?) ?? 0) + time.inSeconds,
    };
    data['days'] = days;
    await _write(data);
  }

  static Future<void> setGoalMinutes(int minutes) async {
    final data = await _read();
    data['goalMinutes'] = minutes;
    await _write(data);
  }

  static Future<void> addSpeedTest(SpeedTestResult result) async {
    final data = await _read();
    final tests = (data['speedTests'] as List<dynamic>?) ?? [];
    tests.add(result.toJson());
    data['speedTests'] = tests;
    await _write(data);
  }

  static Future<StatsSummary> load({DateTime? now}) async {
    final data = await _read();
    final days = (data['days'] as Map<String, dynamic>?) ?? {};
    final goalMinutes = (data['goalMinutes'] as int?) ?? defaultGoalMinutes;
    final today = DateTime(
      (now ?? DateTime.now()).year,
      (now ?? DateTime.now()).month,
      (now ?? DateTime.now()).day,
    );

    DayStats dayStats(DateTime day) {
      final entry = days[_dayKey(day)] as Map<String, dynamic>?;
      return DayStats(day, words: (entry?['words'] as int?) ?? 0, seconds: (entry?['seconds'] as int?) ?? 0);
    }

    bool goalMet(DateTime day) => dayStats(day).seconds >= goalMinutes * 60;

    // Count back from today; if today's goal is not met yet, from yesterday
    var streak = 0;
    var day = goalMet(today) ? today : today.subtract(const Duration(days: 1));
    while (goalMet(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }

    var totalWords = 0;
    var totalSeconds = 0;
    for (final entry in days.values) {
      totalWords += ((entry as Map<String, dynamic>)['words'] as int?) ?? 0;
      totalSeconds += (entry['seconds'] as int?) ?? 0;
    }

    final speedTests = [
      for (final item in (data['speedTests'] as List<dynamic>?) ?? [])
        SpeedTestResult.fromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return StatsSummary(
      goalMinutes: goalMinutes,
      today: dayStats(today),
      lastWeek: [for (var i = 6; i >= 0; i--) dayStats(DateTime(today.year, today.month, today.day - i))],
      streak: streak,
      totalWords: totalWords,
      totalSeconds: totalSeconds,
      speedTests: speedTests,
    );
  }
}
