/// Daily Reminder
///
/// A notification at a chosen time of day ("time to read"), on Android.
/// It is skipped on a day something was already read, and tapping it opens
/// the text that was read last.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_language.dart';
import 'reading_storage.dart';
import 'reading_time.dart';

class DailyReminder {
  static const _key = 'daily_reminder';
  static const _dismissedKey = 'daily_reminder_offer_dismissed';
  static const _id = 1;

  /// Whether the device can show the reminder (not in browsers)
  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The reminder's time, or null when it is off
  static final time = ValueNotifier<TimeOfDay?>(null);

  /// A reminder was tapped: the home screen opens the text read last
  static final openRequested = ValueNotifier<bool>(false);

  static FlutterLocalNotificationsPlugin? _plugin;

  /// Load the setting and (re)schedule the reminder, at app start
  static Future<void> init() async {
    final saved = (await SharedPreferences.getInstance()).getStringList(_key);
    if (saved != null && saved.length == 2) {
      time.value = TimeOfDay(hour: int.tryParse(saved[0]) ?? 20, minute: int.tryParse(saved[1]) ?? 0);
    }
    // Reading today makes today's reminder needless
    ReadingTime.onFirstReadToday = () => _schedule(skipToday: true);
    if (!supported) return;
    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
      } catch (_) {
        // Unknown zone: UTC
      }
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_reader')),
        onDidReceiveNotificationResponse: (_) => openRequested.value = true,
      );
      _plugin = plugin;
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) openRequested.value = true;
      // Again at every start: the language and the goal may have changed
      final readToday = await ReadingTime.load() > 0;
      await _schedule(skipToday: readToday);
    } catch (e) {
      debugPrint('Daily reminder unavailable: $e');
    }
  }

  /// Turn the reminder on at [at]; false when notifications are not allowed
  static Future<bool> enable(TimeOfDay at) async {
    final android = _plugin?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null && await android.requestNotificationsPermission() == false) return false;
    time.value = at;
    await (await SharedPreferences.getInstance()).setStringList(_key, ['${at.hour}', '${at.minute}']);
    await _schedule(skipToday: await ReadingTime.load() > 0);
    return true;
  }

  static Future<void> disable() async {
    time.value = null;
    await (await SharedPreferences.getInstance()).remove(_key);
    await _plugin?.cancel(id: _id);
  }

  /// Whether the home screen still offers to turn the reminder on
  static Future<bool> offerDismissed() async => (await SharedPreferences.getInstance()).getBool(_dismissedKey) ?? false;

  static Future<void> dismissOffer() async => (await SharedPreferences.getInstance()).setBool(_dismissedKey, true);

  /// The next time to remind at [hour]:[minute] after [now]: today if that
  /// is still ahead (and nothing was read today), otherwise tomorrow
  @visibleForTesting
  static DateTime nextTime(DateTime now, int hour, int minute, {bool skipToday = false}) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    return !skipToday && today.isAfter(now) ? today : DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  static Future<void> _schedule({bool skipToday = false}) async {
    final plugin = _plugin;
    final at = time.value;
    if (plugin == null || at == null) return;
    final now = tz.TZDateTime.now(tz.local);
    final next = nextTime(now, at.hour, at.minute, skipToday: skipToday);
    final strings = AppLanguage.strings;
    final goal = (await ReadingStorage.loadSettings()).dailyGoalMinutes;
    await plugin.zonedSchedule(
      id: _id,
      title: strings.reminderTitle,
      body: goal > 0 ? strings.reminderBodyGoal(goal) : strings.reminderBody,
      scheduledDate: tz.TZDateTime(tz.local, next.year, next.month, next.day, next.hour, next.minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          strings.reminderChannel,
          channelDescription: strings.reminderChannelDescription,
        ),
      ),
      // Inexact: no exact alarm permission needed, a few minutes off is fine
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
