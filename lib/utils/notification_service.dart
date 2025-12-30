import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
  }

  static Future<void> showMonthlyReadyNotification(String filePath) async {
    const androidDetails = AndroidNotificationDetails(
      'monthly_report',
      'Monthly Report',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      0,
      'Monthly Report Ready',
      'Tap to open your PDF report',
      NotificationDetails(android: androidDetails),
      payload: filePath,
    );
  }
}
