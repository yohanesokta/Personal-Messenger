import 'dart:io';
import 'package:flutter/material.dart';

const Color themePrimaryColor = Color(0xFF5A2C9D);

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null), // Kirim null jika dibatalkan
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.file(File(widget.imagePath)),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 8, 10 + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tambahkan keterangan...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    backgroundColor: themePrimaryColor,
                    onPressed: () {
                      Navigator.of(context).pop(_captionController.text);
                    },
                    child: const Icon(Icons.send, color: Colors.white),
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