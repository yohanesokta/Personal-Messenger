import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static int _notificationId = 0;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'background_socket_channel',
    'Background Socket Service',
    description: 'Channel for background socket notifications',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_stat_heart');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> createNotificationChannel() async {
    final anp = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await anp?.createNotificationChannel(_channel);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: _channel.importance,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
    ));

    await _notificationsPlugin.show(
      _notificationId++,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}