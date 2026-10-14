// lib/features/notifications/domain/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants/app_constants.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleMaintenanceReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });

  /// Schedules 8 daily reminders at 09:00 local: today and the next 7 days.
  /// Uses ids [baseId, baseId+1, ..., baseId+7].
  Future<void> scheduleOdometerDueReminders({
    required int baseId,
    required String title,
    required String body,
  });
  Future<void> cancelNotification(int id);

  /// Cancels notifications with ids [baseId, baseId+1, ..., baseId+count-1].
  Future<void> cancelNotificationRange(int baseId, int count);
  Future<void> cancelAllNotifications();
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  });
}

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> scheduleMaintenanceReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Non-critical — never block the save flow
    }
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  @override
  Future<void> scheduleOdometerDueReminders({
    required int baseId,
    required String title,
    required String body,
  }) async {
    await showInstantNotification(id: baseId, title: title, body: body);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 7; i++) {
      final scheduledDate = startOfToday.add(Duration(days: i));
      final atNine = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9,
        0,
      );
      try {
        await scheduleMaintenanceReminder(
          id: baseId + i,
          title: title,
          body: body,
          scheduledDate: atNine,
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  @override
  Future<void> cancelNotificationRange(int baseId, int count) async {
    try {
      for (int i = 0; i < count; i++) {
        await _plugin.cancel(baseId + i);
      }
    } catch (_) {}
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }
}
