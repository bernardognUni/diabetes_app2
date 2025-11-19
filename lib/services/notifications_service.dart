import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationsService {
  static final NotificationsService _i = NotificationsService._();
  NotificationsService._();
  factory NotificationsService() => _i;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    bool sound = true,
    bool vibration = true,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'lembretes', 'Lembretes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: sound,
        enableVibration: vibration,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }
}
