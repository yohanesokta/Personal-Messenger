import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';
import 'notification_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> getDeviceId() async {
  final info = DeviceInfoPlugin();
  final android = await info.androidInfo;
  return android.model ?? 'unknown-device';
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      autoStartOnBoot: true,
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      foregroundServiceTypes: [
        AndroidForegroundType.dataSync,
      ],
      notificationChannelId: 'background_socket_channel',
      initialNotificationTitle: 'Aplikasi Yohanes Berjalan',
      initialNotificationContent: 'Beliau Mengintai Di Background...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationHelper.initialize();
  await dotenv.load(fileName: '.env');
  late IO.Socket socket;
  final myDeviceId = await getDeviceId();
  if (service is AndroidServiceInstance) {
    print("ANJAYYYYYYYYYYY FORGROUND!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    service.setAsForegroundService();
  }
  void connectToSocket() {
    socket = IO.io(dotenv.env['SOCKET_URL'], <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      debugPrint('SOCKET CONNECTED: ${socket.id}');
      NotificationHelper.showNotification(title: "Koneksi",
          body: "Koneksi Berhasil Dilakukan."
      );
      service.invoke(
        'update',
        {
          "message": "Socket Terhubung",
        },
      );
    });

    socket.on('message', (data) {
      final messages = jsonDecode(data.toString()) as Map<String, dynamic>;
        if (messages["device_id"] != myDeviceId) {
          NotificationHelper.showNotification(
            title: 'Dari Kekasihmu ❤︎',
            body: messages['message'],
          );
        }
          service.invoke("message");
    });

    socket.onDisconnect((_) {
      debugPrint('SOCKET DISCONNECTED');
      NotificationHelper.showNotification(title: "Koneksi",
          body: "Memeriksa Pesan Baru.."
      );
      service.invoke(
        'update',
        {
          "message": "Socket Terputus",
        },
      );
    });

    socket.onError((error) {
      debugPrint('SOCKET ERROR: $error');
    });

    socket.connect();
  }

  connectToSocket();

  service.on('stopService').listen((event) {
    socket.disconnect();
    socket.dispose();
    service.stopSelf();
  });
}