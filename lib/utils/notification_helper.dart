// lib/notification_helper.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static int _notificationId = 0;

  // Definisikan detail channel di sini agar bisa digunakan bersama
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'background_socket_channel', // ID Channel (HARUS SAMA dengan di background_service.dart)
    'Background Socket Service',   // Nama Channel
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

  // !! FUNGSI BARU UNTUK MEMBUAT CHANNEL !!
  static Future<void> createNotificationChannel() async {
    // Pastikan hanya berjalan di Android
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
      _channel.id, // Gunakan ID channel yang sudah dibuat
      _channel.name,
      channelDescription: _channel.description,
      importance: _channel.importance,
      priority: Priority.high,
      showWhen: true,
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