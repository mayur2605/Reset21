import 'dart:developer' as dev;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Local notification service for daily reminders.
/// Morning: "Day X starts. Don't break your streak."
/// Evening: "You're close. Lock your day."
/// All operations wrapped in try-catch for crash safety.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );
    } catch (e) {
      dev.log('[NotificationService] initialize failed: $e', name: 'Reset21');
    }
  }

  /// Schedule morning (8 AM) and evening (9 PM) reminders.
  static Future<void> scheduleDailyReminders({required int currentDay}) async {
    try {
      await _plugin.cancelAll();

      // Morning – 8:00 AM
      await _scheduleDaily(
        id: 0,
        hour: 8,
        minute: 0,
        title: 'Reset21 – Day $currentDay',
        body: "Day $currentDay starts. Don't break your streak. 🔥",
      );

      // Evening – 9:00 PM
      await _scheduleDaily(
        id: 1,
        hour: 21,
        minute: 0,
        title: 'Reset21 – Lock Your Day',
        body: "You're close. Lock your day and earn XP. 💪",
      );
    } catch (e) {
      dev.log('[NotificationService] scheduleDailyReminders failed: $e', name: 'Reset21');
    }
  }

  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'reset21_reminders',
        'Daily Reminders',
        channelDescription: 'Daily habit reminders for Reset21',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        title: title,
        body: body,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      dev.log('[NotificationService] _scheduleDaily(id=$id) failed: $e', name: 'Reset21');
    }
  }
}
