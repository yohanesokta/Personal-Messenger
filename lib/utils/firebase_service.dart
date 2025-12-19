import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:secret_love/context.dart';

/// This handler is the single entry point for FCM messages received when the app
/// is in the background or terminated.
///
/// It must be a top-level function and self-contained to prevent crashes
/// related to accessing UI/engine features from a background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Flutter engine bindings are available for plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize core plugins
  await Firebase.initializeApp();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 2. Perform minimal, self-contained initialization for notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_heart');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 3. Define and create the notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'background_socket_channel', // Use a consistent channel ID
    'Pesan Baru',
    description: 'Channel untuk notifikasi pesan masuk.',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  debugPrint("--- FCM Background Handler Fired ---");

  final title = message.notification?.title ?? "Pesan Baru";
  final body = message.notification?.body ?? "Kamu menerima pesan baru.";

  // 4. Directly show the notification
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@drawable/ic_stat_heart',
        priority: Priority.high,
        importance: Importance.max,
      ),
    ),
  );
}

/// A service class to manage Firebase listeners for the foreground app.
class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  /// Sets up the listeners for when the app is in the foreground.
  void setupForegroundListeners({required ContextService contextService}) {
    // This listener fires when the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('--- FCM FOREGROUND MESSAGE RECEIVED ---');
      // Instead of showing a notification, we reload the chat data
      // to provide a real-time experience in-app.
      contextService.loadFromAPI();
    });

    // This listener fires when the app is opened from a notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('--- APP OPENED FROM NOTIFICATION ---');
      // Here you could add logic to navigate to a specific chat screen.
      // For now, we just ensure the data is fresh.
      contextService.loadFromAPI();
    });
  }
}