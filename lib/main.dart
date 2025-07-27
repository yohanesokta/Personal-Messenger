// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '/components/menu.dart';
import '/components/settings.dart';
import '/components/webview_calls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/background_service.dart';
import 'utils/notification_helper.dart';
import 'package:provider/provider.dart';
import 'context.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import "components/key_saver.dart" as key_server;

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
    Permission.videos,
    Permission.mediaLibrary,
    Permission.ignoreBatteryOptimizations,
  ].request();

  statuses.forEach((perm, status) {
    print('Permission $perm: $status');
  });
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late ContextService contextService;
  late String myDeviceId;
  try {
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
    await dotenv.load(fileName:'.env');

    await requestAllPermissions();
    await NotificationHelper.initialize();

    await NotificationHelper.createNotificationChannel();

    await initializeService();

    myDeviceId = await getDeviceId();
    contextService = ContextService(myDeviceId: myDeviceId);
    await contextService.loadFromAPI();
  } catch (error) {
    debugPrint(error.toString());
  }


  FlutterBackgroundService().on("message").listen((event) {
    contextService.loadFromAPI();
  });
  final webrtcUrl = dotenv.env['SOCKET_URL']!;
  runApp(ChangeNotifierProvider.value(value: contextService, child: MyApp(deviceId: myDeviceId,webrtcUrl: webrtcUrl,),));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.deviceId, required this.webrtcUrl});
  final String deviceId;
  final String webrtcUrl;

  @override
  Widget build(BuildContext context) {



    return MaterialApp(
      title: 'Flutter Background Socket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: KeyWiget(),
      routes: <String, WidgetBuilder>{
        "/menu" : (BuildContext context) => Menu(),
        "/settings" : (BuildContext context) => Settings(),
        "/remotecam" : (BuildContext context) => VideoCallView(webRtcUrl: "$webrtcUrl/cam?device=$deviceId",),
        "/remotecall" : (BuildContext context) => VideoCallView(webRtcUrl: "$webrtcUrl/call?device=$deviceId",),
        "/keysaver" : (BuildContext context) => key_server.View(),
      },
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

  void secretChage(value) {
    print(password_text);
    if (value.toString().length >= password_text.length) {
      if (checkPass(value)) {
        txtpass.text = "";
        setState(() {
          _failPass = true;
        });
      } else {
        FlutterBackgroundService().startService();
        FlutterBackgroundService().invoke("setAsForeground");

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
      appBar: AppBar(title: Text("Mode YTTA")),
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
