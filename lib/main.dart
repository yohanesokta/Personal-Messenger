
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secret_love/utils/app_lifecycle_handler.dart';
import '/components/menu.dart';
import '/components/settings.dart';
import '/components/webview_calls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'context.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import "components/key_saver.dart" as key_server;
import 'utils/background_service.dart';
import 'utils/firebase_service.dart';

Future<String> getDeviceId() async {
  final info = DeviceInfoPlugin();
  final android = await info.androidInfo;
  return android.model ?? 'unknown-device';
}

Future<void> requestAllPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.notification,
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.photos,
  ].request();

  statuses.forEach((permission, status) {
    debugPrint('Izin ${permission.toString()}: $status');
  });
}

Future<void> handleBatteryOptimization(BuildContext context) async {
  PermissionStatus status = await Permission.ignoreBatteryOptimizations.status;
  debugPrint('Status optimisasi baterai: $status');

  if (status.isDenied) {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perizinan Diperlukan'),
        content: const Text(
            'Aplikasi ini memerlukan izin untuk berjalan tanpa batasan baterai agar notifikasi dan layanan dapat berfungsi dengan baik setiap saat.\n\nAnda akan diarahkan ke Pengaturan.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Permission.ignoreBatteryOptimizations.request();
            },
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground_service',
    'Layanan Latar Belakang',
    description: 'Channel ini digunakan untuk layanan latar belakang.',
    importance: Importance.max,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await initializeService();
  final service = FlutterBackgroundService();
  late ContextService contextService;
  late String myDeviceId;
  late GlobalKey<NavigatorState> navigatorKey;

  try {
    await dotenv.load(fileName: '.env');

    await requestAllPermissions();

    myDeviceId = await getDeviceId();
    contextService = ContextService(myDeviceId: myDeviceId);
    // The initial load is now handled inside the ContextService's _init method.
    // await contextService.loadFromAPI(); // This is no longer needed here.

    service.on("mew_message").listen((message) async {
      // Use the new, efficient method to fetch only new messages
      // Convert DateTime to ISO 8601 String for the 'after' parameter
      await contextService.fetchMessages(after: contextService.chats.firstOrNull?.createAt?.toIso8601String());
    });
    FirebaseService.instance.setupListeners(contextService: contextService);

  } catch (error) {
    debugPrint("Error during initialization: ${error.toString()}");
  }


  final webrtcUrl = dotenv.env['SOCKET_URL']!;
  navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    ChangeNotifierProvider.value(
      value: contextService,
      child: MyApp(
          contextService: contextService,
          deviceId: myDeviceId,
          webrtcUrl: webrtcUrl,
          navigatorKey: navigatorKey,
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (navigatorKey.currentContext != null) {
      await handleBatteryOptimization(navigatorKey.currentContext!);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.deviceId,
    required this.webrtcUrl,
    required this.navigatorKey,
    required this.contextService
  });
  final String deviceId;
  final String webrtcUrl;
  final GlobalKey<NavigatorState> navigatorKey;
  final ContextService contextService;

  @override
  Widget build(BuildContext context) {
    return LifecycleWatcher(
      contextService: contextService,
      navigatorKey: navigatorKey,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Hanya Kita Berdua',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: KeyWiget(),
        routes: <String, WidgetBuilder>{
          "/key" : (BuildContext context) => KeyWiget(),
          "/menu": (BuildContext context) => Menu(),
          "/settings": (BuildContext context) => Settings(),
          "/remotecam": (BuildContext context) => VideoCallView(
            webRtcUrl: "$webrtcUrl/cam?device=$deviceId",
          ),
          "/remotecall": (BuildContext context) => VideoCallView(
            webRtcUrl: "$webrtcUrl/call?device=$deviceId",
          ),
          "/keysaver": (BuildContext context) => key_server.View(),
        },
      ),
    );
  }
}

class KeyWiget extends StatefulWidget {
  const KeyWiget({super.key});
  @override
  State<KeyWiget> createState() => _KeyWigetState();
}

class _KeyWigetState extends State<KeyWiget> {
  bool _failPass = false;
  var txtpass = TextEditingController();
  String password_text = "12345";

  void _initialize_password() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? pins = prefs.getString("pins");
    if (pins != null) {
      password_text = pins.toString();
    }
  }

  bool checkPass(value) {
    return value != password_text;
  }

  void secretChage(value) async {
    if (value.toString().length >= password_text.length) {
      if (checkPass(value)) {
        txtpass.text = "";
        setState(() {
          _failPass = true;
        });
      } else {
        FlutterBackgroundService().startService();

        txtpass.text = "";
        Navigator.pushReplacementNamed(context, '/menu');
      }
    } else {
      setState(() {
        _failPass = false;
      });
    }
  }

  @override
  void initState() {
    _initialize_password();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hanya Kita Berdua")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.lock, color: Colors.blue, size: 25.0),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "Buka Kunci Aplikasi",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 100),
              child: TextField(
                controller: txtpass,
                autofocus: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
                keyboardType: TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: secretChage,
              ),
            ),
            if (_failPass) ...[
              Text("Kunci Salah", style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}