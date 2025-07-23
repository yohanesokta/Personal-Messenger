import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var pin_input = TextEditingController();

  Future<void> _writepindata() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("pins", pin_input.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("pin berhasil di ganti"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setting')),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              "Ubah PIN",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Ubah pin dengan pin baru. pastikan selalu mengingat pin karena tidak bisa reset jika lupa dan harus menghapus data!",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: pin_input,
              obscureText: true,
              obscuringCharacter: "*",
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              decoration: InputDecoration(
                label: Text("Massukan Pin Baru"),
                fillColor: Colors.blue,
                focusColor: Colors.blue,
                hintText: "Contohe ngene 1234",
                border: OutlineInputBorder(),
                suffix: Icon(Icons.lock, size: 18, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: _writepindata,
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  alignment: Alignment.center,
                  child: Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
