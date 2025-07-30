// lib/utils/background_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _notificationChannelId = 'my_foreground_service';
const String _fcmMessageKey = 'fcm_message';

Future<String> getDeviceId() async {
  final info = DeviceInfoPlugin();
  final android = await info.androidInfo;
  return android.model ?? 'unknown-device';
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  final myDeviceId = await getDeviceId();
  debugPrint("Background Service Started. My Device ID: $myDeviceId");

  // Timer untuk memeriksa "kotak surat" (SharedPreferences) setiap 2 detik
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final messageString = prefs.getString(_fcmMessageKey);

    if (messageString != null) {
      debugPrint("Background Service: Menemukan pesan baru di SharedPreferences!");

      // Hapus pesan agar tidak diproses lagi
      await prefs.remove(_fcmMessageKey);
      final Map<String, dynamic> event = jsonDecode(messageString);
      final String deviceIdFromServer = event['device_id'] ?? '';
      final bool isSilent = event['silent'] == 'true';
      if (isSilent) {
        debugPrint("Silent message processed, not showing notification.");
        return;
      }
      if (deviceIdFromServer != myDeviceId) {
        flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecond,
          event['title'] ?? 'Dari Kekasihmu ❤︎',
          event['body'] ?? 'Kamu menerima pesan baru.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _notificationChannelId,
              'Layanan Latar Belakang',
              channelDescription: 'Channel ini digunakan untuk layanan latar belakang.',
              priority: Priority.high,
              importance: Importance.max,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
      service.invoke("mew_message");
    }
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: _notificationChannelId,
      initialNotificationTitle: 'Aplikasi Siaga',
      initialNotificationContent: 'Menunggu pesan dari kekasihmu...',
      foregroundServiceNotificationId: 888,
    ),
  );
}