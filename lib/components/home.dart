import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        durationDetail = "Silakan tunggu hingga waktunya tiba.";
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
      DateTime lastDayOfPreviousMonth = DateTime(now.year, now.month, 0);
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

  Widget _buildGlassContainer({
    required Widget child,
    double padding = 16.0,
    Color shadowColor = Colors.black,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: -5,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, {IconData? icon, Color? iconColor, required Color shadowColor}) {
    final Color textColor = Colors.grey.shade800;
    return _buildGlassContainer(
      padding: 12,
      shadowColor: shadowColor,
      child: icon != null
          ? Icon(icon, size: 22, color: iconColor)
          : Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryTextColor = Colors.grey.shade900;
    final Color secondaryTextColor = Colors.grey.shade700;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Kita Berdua",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryTextColor),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: Icon(Icons.settings, color: primaryTextColor),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.yellow.shade600.withOpacity(0.7), Color(0xFFF5F7FA).withOpacity(0.1)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.cyan.shade300.withOpacity(0.8), Color(0xFFF5F7FA).withOpacity(0.1)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDateChip("29", shadowColor: Colors.yellow.shade600),
                      _buildDateChip("Maret", shadowColor: Colors.yellow.shade600),
                      _buildDateChip("2024", shadowColor: Colors.yellow.shade600),
                      _buildDateChip(
                        "",
                        icon: Icons.shield_moon_rounded,
                        iconColor: Colors.pink.shade400,
                        shadowColor: Colors.pink.shade400,
                      ),
                    ],
                  ),
                  Spacer(flex: 2),
                  _buildGlassContainer(
                    padding: 24,
                    // Memberikan warna shadow sesuai elemen dekoratif terdekat
                    shadowColor: Colors.cyan.shade300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          durationString,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          durationDetail,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(flex: 3),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassContainer(
                          padding: 0,
                          shadowColor: Colors.orange.shade700,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/keysaver'),
                            icon: Icon(Icons.key_rounded, color: Colors.orange.shade700),
                            label: Text("Key Saver", style: GoogleFonts.poppins(color: primaryTextColor, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildGlassContainer(
                          padding: 0,
                          shadowColor: Colors.blue.shade700,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pushNamed(context, "/remotecam"),
                            icon: Icon(Icons.camera_alt_rounded, color: Colors.blue.shade700),
                            label: Text("Remote Cam", style: GoogleFonts.poppins(color: primaryTextColor, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}