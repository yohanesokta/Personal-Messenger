import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotification();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _messaging =   FirebaseMessaging.instance;
  final _localNotification = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupMessageHandlers();
    final token = await _messaging.getToken();
    print("FCM TOKEN $token");
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false
    );
    
    print("Permision Status : ${settings.authorizationStatus}");
  }

  Future<void> setupFlutterNotification() async {
    if (_isFlutterLocalNotificationInitialized) {
      return;
    }

    const chanel = AndroidNotificationChannel(
      "high_chanel",
      "Hight Importance Notification",
      description: "This Channel Use For FCM",
      importance: Importance.high
    );

    await _localNotification
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(chanel);

    const initializationSettingAndroid = 
        AndroidInitializationSettings(('@mipmap/ic_launcher'));

    final initializationSettings = InitializationSettings(
      android: initializationSettingAndroid
    );

    await _localNotification.initialize(initializationSettings,onDidReceiveNotificationResponse: (details) {

    });
    _isFlutterLocalNotificationInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      await _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            "high_chanel",
            "Hight Importance Notification",
            channelDescription:
                "This Channel Use For FCM",
            importance: Importance.high,
            priority: Priority.high,
            icon: "@mipmap/ic_launcher",
          )
        ),
          payload: message.data.toString()
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    //forground message
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    void _handleBackgroundMessage(RemoteMessage message) {
      if (message.data['type'] == 'chat') {

      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);


  }
}