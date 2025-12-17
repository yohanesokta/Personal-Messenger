import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:secret_love/context.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _fcmMessageKey = 'fcm_message';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("--- FCM Background Handler ---");
  debugPrint("Data: ${message.data}");
  if (message.data['silent'] == 'true' || message.data['silent'] == true) {
    debugPrint("Pesan silent diterima di background, tidak ada notifikasi akan ditampilkan.");
  } else {
    debugPrint("Menulis pesan ke SharedPreferences untuk notifikasi.");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmMessageKey, jsonEncode(message.data));
  }
}

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  ContextService? _contextService;

  void setupListeners({required ContextService contextService}) {
    _contextService = contextService;
    _setupForegroundMessageHandler();
  }

  void _setupForegroundMessageHandler() {
   final _firebaseMassaging =  FirebaseMessaging.instance.subscribeToTopic('message');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('--- PESAN DITERIMA DI FOREGROUND ---');
      debugPrint("Data: ${message.data}");
      _contextService?.loadFromAPI();
      if (message.data['silent'] != 'true' && message.data['silent'] != true) {
        debugPrint("Pesan normal, memicu update UI.");
      } else {
        debugPrint("Pesan silent, hanya update data di UI tanpa notifikasi.");
      } 
    });
  }
}