import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

const String _notificationChannelId = 'my_foreground_service';

// This is the new entry point for the background service isolate.
// Its purpose is simply to keep the service running.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure plugins are initialized in this isolate
  DartPluginRegistrant.ensureInitialized();
  debugPrint("Persistent Background Service Started.");

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  // The service can listen for custom events if needed in the future,
  // for example, to manage a WebSocket connection.
  // For now, it just runs.
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      // iOS configuration
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true, // IMPORTANT: Auto-start the service
      notificationChannelId: _notificationChannelId,
      initialNotificationTitle: 'Personal Messenger',
      initialNotificationContent: 'Layanan berjalan untuk memastikan koneksi realtime.',
      foregroundServiceNotificationId: 888,
    ),
  );
}