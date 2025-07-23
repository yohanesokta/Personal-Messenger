import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:ui'; // Diperlukan untuk BackdropFilter

class VideoCallView extends StatefulWidget {
  // Ganti URL ini dengan URL halaman web WebRTC Anda
  final String webRtcUrl;

  const VideoCallView({
    super.key,
    this.webRtcUrl = "https://webrtc.yohanes.dpdns.org/2" // Placeholder
  });

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      if (_controlsVisible) {
        _startHideControlsTimer();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Menjalankan fungsi JavaScript di dalam WebView
    _webViewController?.evaluateJavascript(source: 'toggleMuteInJS()');
    _startHideControlsTimer(); // Reset timer setiap ada interaksi
  }

  void _endCall() {
    // Menjalankan fungsi JavaScript untuk menutup koneksi sebelum keluar
    _webViewController?.evaluateJavascript(source: 'hangUpInJS()');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Ganti fungsi build() Anda dengan yang ini
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 20, 20),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // --- Lapisan 1: WebView untuk Video Call (Paling Bawah) ---
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.webRtcUrl)),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              iframeAllow: "camera; microphone",
              javaScriptEnabled: true,
              transparentBackground: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
          ),

          // --- Lapisan 2: Pendeteksi Ketukan (Di Atas WebView) ---
          // Lapisan transparan ini tugasnya hanya satu: mendeteksi saat Anda mengetuk layar
          // untuk memunculkan/menyembunyikan kontrol.
          GestureDetector(
            onTap: _toggleControls,
            // Ini membuat GestureDetector bisa mendeteksi ketukan di area transparan
            behavior: HitTestBehavior.translucent,
            child: Container(
              // Container kosong ini memastikan GestureDetector mengisi seluruh layar
              color: Colors.transparent,
            ),
          ),

          // --- Indikator Loading ---
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // --- Lapisan 3: Overlay Kontrol (Paling Atas) ---
          // Kode untuk _buildControlsOverlay() tidak berubah, kita hanya memanggilnya di sini.
          _buildControlsOverlay(),
        ],
      ),
    );
  }
  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildControlButton(
                        onPressed: _toggleMute,
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        backgroundColor: _isMuted ? const Color(0xFF5865f2) : const Color(0xFF36393f),
                      ),
                      const SizedBox(width: 24),
                      _buildControlButton(
                        onPressed: _endCall,
                        icon: Icons.call_end,
                        backgroundColor: const Color(0xFFed4245),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.call_end, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}