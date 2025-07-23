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
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceId() async {
  final info = DeviceInfoPlugin();
  final android = await info.androidInfo;
  return android.model ?? 'unknown-device';
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  await NotificationHelper.initialize();

  await NotificationHelper.createNotificationChannel();

  await initializeService();

  final myDeviceId = await getDeviceId();
  final contextService = ContextService(myDeviceId: myDeviceId);
  await contextService.loadFromAPI();

  FlutterBackgroundService().on("message").listen((event) {
    contextService.loadFromAPI();
  });
  
  runApp(ChangeNotifierProvider.value(value: contextService, child: MyApp(),));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        "/remotecam" : (BuildContext context) => VideoCallView(webRtcUrl: "https://webrtc.yohanes.dpdns.org/cam",),
        "/remotecall" : (BuildContext context) => VideoCallView(webRtcUrl: "https://webrtc.yohanes.dpdns.org/call",),
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
    print(password_text);
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
      appBar: AppBar(title: Text("Secret")),
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
