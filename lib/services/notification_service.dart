import 'package:birthday/core/constants/app_constants.dart';
import 'package:birthday/data/models/person.dart' as model;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Request POST_NOTIFICATIONS permission on Android 13+
    await androidImpl?.requestNotificationsPermission();

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Reminders for upcoming birthdays',
      importance: Importance.high,
    ));

    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.hourlyChannelId,
      AppConstants.hourlyChannelName,
      description: 'Hourly alerts for birthdays happening today',
      importance: Importance.high,
    ));

    _initialized = true;
  }

  Future<void> rescheduleAll(List<model.Person> allPeople) async {
    await _plugin.cancelAll();
    for (final person in allPeople) {
      await _scheduleBirthdayNotif(person);
      await _scheduleReminderNotif(person);
    }
  }

  Future<void> _scheduleBirthdayNotif(model.Person person) async {
    try {
      final next = _nextBirthdayTZ(person.birthday, hour: AppConstants.birthdayNotifHour);
      if (next.isBefore(tz.TZDateTime.now(tz.local))) return;

      final id = AppConstants.birthdayNotifBaseId + person.id.hashCode.abs() % 900;
      await _plugin.zonedSchedule(
        id,
        '🎂 Happy Birthday, ${person.name}!',
        "Today is ${person.name}'s birthday! Don't forget to celebrate!",
        next,
        _notifDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> _scheduleReminderNotif(model.Person person) async {
    try {
      final next = _nextBirthdayTZ(
        person.birthday,
        hour: AppConstants.reminderNotifHour,
      ).subtract(const Duration(days: 2));
      if (next.isBefore(tz.TZDateTime.now(tz.local))) return;

      final id = AppConstants.reminderNotifBaseId + person.id.hashCode.abs() % 900;
      await _plugin.zonedSchedule(
        id,
        "⏰ ${person.name}'s birthday is in 2 days!",
        "Get ready to celebrate ${person.name}! 🎉",
        next,
        _notifDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  tz.TZDateTime _nextBirthdayTZ(DateTime birthday, {required int hour}) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      birthday.month,
      birthday.day,
      hour,
    );
    if (next.isBefore(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year + 1,
        birthday.month,
        birthday.day,
        hour,
      );
    }
    return next;
  }

  NotificationDetails _notifDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: 'Reminders for upcoming birthdays',
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
  }

  Future<void> cancelForPerson(String personId) async {
    final birthdayId =
        AppConstants.birthdayNotifBaseId + personId.hashCode.abs() % 900;
    final reminderId =
        AppConstants.reminderNotifBaseId + personId.hashCode.abs() % 900;
    await _plugin.cancel(birthdayId);
    await _plugin.cancel(reminderId);
  }

  /// Schedules hourly notifications for today (from 8am to 10pm) for a person
  /// whose birthday is today. Call this after checking that [person.isBirthdayToday].
  Future<void> scheduleHourlyTodayNotifs(model.Person person) async {
    final now = tz.TZDateTime.now(tz.local);
    final personHash = person.id.hashCode.abs() % 900;
    final baseId = AppConstants.hourlyNotifBaseId + personHash * 100;

    for (var hour = AppConstants.hourlyStartHour;
        hour <= AppConstants.hourlyEndHour;
        hour++) {
      final slot = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (slot.isBefore(now)) continue; // skip past slots

      final offsetIndex = hour - AppConstants.hourlyStartHour;
      final id = baseId + offsetIndex;

      try {
        await _plugin.zonedSchedule(
          id,
          '🎂 Aniversário de ${person.name} é hoje!',
          'Não esqueça de mandar parabéns. Toque para celebrar! 🎉',
          slot,
          _hourlyNotifDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  /// Cancels all hourly today-notifications for a person (called on "Verificado").
  Future<void> cancelHourlyTodayNotifs(String personId) async {
    final personHash = personId.hashCode.abs() % 900;
    final baseId = AppConstants.hourlyNotifBaseId + personHash * 100;
    final slotCount =
        AppConstants.hourlyEndHour - AppConstants.hourlyStartHour + 1;
    for (var i = 0; i < slotCount; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  NotificationDetails _hourlyNotifDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.hourlyChannelId,
        AppConstants.hourlyChannelName,
        channelDescription: 'Hourly alerts for birthdays happening today',
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
  }
}

