import 'dart:async';
import 'package:flutter/material.dart';

class Utama extends StatefulWidget {
  const Utama({Key? key}) : super(key: key);

  @override
  _UtamaState createState() => _UtamaState();
}

class _UtamaState extends State<Utama> {
  final DateTime targetDate = DateTime(2024, 3, 29, 1, 0, 0);
  String durationString = "Menghitung...";
  String durationDetail = "Menghitung...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calculateAndUpdateDuration();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      _calculateAndUpdateDuration();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateAndUpdateDuration() {
    DateTime now = DateTime.now();

    if (now.isBefore(targetDate)) {
      setState(() {
        durationString = "Tanggal target belum tercapai.";
        durationDetail = "Tanggal target belum tercapai.";
      });
      return;
    }

    int years = now.year - targetDate.year;
    int months = now.month - targetDate.month;
    int days = now.day - targetDate.day;
    int hours = now.hour - targetDate.hour;
    int minutes = now.minute - targetDate.minute;
    int seconds = now.second - targetDate.second;

    if (seconds < 0) {
      seconds += 60;
      minutes--;
    }
    if (minutes < 0) {
      minutes += 60;
      hours--;
    }
    if (hours < 0) {
      hours += 24;
      days--;
    }
    if (days < 0) {
      months--;
      DateTime lastDayOfPreviousMonth;
      if (now.month == 1) {
        lastDayOfPreviousMonth = DateTime(now.year - 1, 12, 0);
      } else {
        lastDayOfPreviousMonth = DateTime(now.year, now.month, 0);
      }
      days += lastDayOfPreviousMonth.day;
    }
    if (months < 0) {
      months += 12;
      years--;
    }

    setState(() {
      durationString = "$years tahun $months bulan $days hari";
      durationDetail = "$hours jam : $minutes menit : $seconds detik";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("Kita Berdua", style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120.0,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      spacing: 5,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "29",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Maret",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "2024",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.shield_moon,
                            size: 20,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 60, left: 10, right: 10),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Container(
                      padding: EdgeInsets.only(top: 35),
                      child: Column(
                        spacing: 5,
                        children: [
                          Text(
                            durationString,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(durationDetail),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Row(
                children: [
                  FilledButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 30,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/keysaver');
                    },
                    label: Text(
                      "Key Saver",
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(Icons.key, color: Colors.white),
                  ),
                  Spacer(),
                  FilledButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        103,
                        156,
                        181,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context,"/remotecam");
                    },
                    label: Text(
                      "Remote Camera",
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(Icons.camera, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
