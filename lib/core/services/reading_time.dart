/// Reading Time
///
/// How long was read today, for the daily goal: the time the speed reader
/// plays and the time a text page is read. Only today's total is kept, on
/// the device.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingTime {
  static const _key = 'reading_time_today';

  /// The clock; tests set their own
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// Seconds read today, for the home screen
  static final today = ValueNotifier<int>(0);

  /// Called once a day, the first time something is read (the daily
  /// reminder is not needed that day)
  static VoidCallback? onFirstReadToday;

  static String _date(DateTime time) =>
      '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

  /// Seconds read today, from storage
  static Future<int> load() async {
    final saved = (await SharedPreferences.getInstance()).getStringList(_key);
    final seconds = saved != null && saved.length == 2 && saved[0] == _date(now()) ? int.tryParse(saved[1]) ?? 0 : 0;
    today.value = seconds;
    return seconds;
  }

  /// Add [seconds] read now; true when this reached the [goalMinutes] of
  /// today (only the once)
  static Future<bool> add(int seconds, {required int goalMinutes}) async {
    if (seconds <= 0) return false;
    final before = await load();
    final after = before + seconds;
    today.value = after;
    await (await SharedPreferences.getInstance()).setStringList(_key, [_date(now()), '$after']);
    if (before == 0) onFirstReadToday?.call();
    final goal = goalMinutes * 60;
    return goal > 0 && before < goal && after >= goal;
  }
}

/// Counts the time while reading is going on and adds it to [ReadingTime]
/// every half minute and when it stops
class ReadingClock {
  /// The daily goal at the moment (the settings can change while reading)
  final int Function() goalMinutes;

  /// Today's goal was just reached
  final VoidCallback? onGoalReached;

  /// Without any [touch] for this long, the time stops counting (a page left
  /// open is not read); null: counts until [stop]
  final Duration? idleLimit;

  ReadingClock({required this.goalMinutes, this.onGoalReached, this.idleLimit});

  DateTime? _since;
  DateTime _lastActive = ReadingTime.now();
  Timer? _flush;

  bool get isRunning => _flush != null;

  void start() {
    if (isRunning) return;
    _lastActive = ReadingTime.now();
    _since = _lastActive;
    _flush = Timer.periodic(const Duration(seconds: 30), (_) => _commit());
  }

  /// The reader did something (scrolled, tapped, the guide moved on)
  void touch() {
    _lastActive = ReadingTime.now();
    if (isRunning) _since ??= _lastActive;
  }

  void stop() {
    if (!isRunning) return;
    _flush?.cancel();
    _flush = null;
    _commit();
    _since = null;
  }

  void _commit() {
    final since = _since;
    if (since == null) return;
    var end = ReadingTime.now();
    final limit = idleLimit;
    final idle = limit != null && end.isAfter(_lastActive.add(limit));
    if (idle) end = _lastActive.add(limit);
    final seconds = end.difference(since).inSeconds;
    if (seconds <= 0) return;
    // Idle: count again from the next touch
    _since = idle ? null : since.add(Duration(seconds: seconds));
    ReadingTime.add(seconds, goalMinutes: goalMinutes()).then((reached) {
      if (reached) onGoalReached?.call();
    });
  }
}
