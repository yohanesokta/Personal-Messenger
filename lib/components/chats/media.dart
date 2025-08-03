import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

const Color themePrimaryColor = Color(0xFF5A2C9D);
final ImagePicker _picker = ImagePicker();

class MediaPickerScreen extends StatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  List<AssetEntity> _assets = [];
  AssetPathEntity? _album;
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  int _selectedCameraIndex = 0;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initAssets();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _selectedCameraIndex = 0;
        _cameraController = CameraController(
          _cameras[_selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    final CameraDescription selectedCamera = _cameras[_selectedCameraIndex];

    await _cameraController?.dispose();
    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isNotEmpty) {
        _album = albums.first;
        await _loadMoreAssets();
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_isLoading || !_hasMore || _album == null) return;

    setState(() => _isLoading = true);
    final List<AssetEntity> nextAssets =
    await _album!.getAssetListPaged(page: _currentPage, size: 60);

    setState(() {
      _assets.addAll(nextAssets);
      _currentPage++;
      _isLoading = false;
      if (nextAssets.isEmpty) _hasMore = false;
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController?.value.isInitialized != true) return;
    try {
      final XFile image = await _cameraController!.takePicture();
      if (mounted) Navigator.of(context).pop(image);
    } catch (e) {
      debugPrint("Take picture error: $e");
    }
  }

  Future<void> _onImageTap(AssetEntity asset) async {
    final File? file = await asset.originFile;
    if (file != null && mounted) {
      Navigator.of(context).pop(XFile(file.path));
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Fullscreen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),

          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 4),
                  ),
                  child: const Icon(Icons.camera_alt, color: themePrimaryColor),
                ),
              ),
            ),
          ),

          Positioned(
            top: 33,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              iconSize: 32,
              onPressed: _switchCamera,
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.18,
            minChildSize: 0.18,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _assets.length + 1, // Tambah 1 untuk tombol "Media"
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () async {
                          final XFile? pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );

                          if (pickedFile != null) {
                            if (mounted) Navigator.of(context).pop(pickedFile);
                          }
                        },
                        child: Container(
                          color: const Color.fromARGB(255, 17, 17, 17),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 10,
                            
                            children: [Icon(Icons.image_rounded,size: 40,color: Colors.white,), Text("Browse Media",style: TextStyle(fontSize: 12,color: Colors.white),)]
                          ),
                        ),
                      );
                    }
                    final asset = _assets[index - 1]; // offset karena index ke-0 untuk tombol
                    return FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                      builder: (_, snapshot) {
                        final bytes = snapshot.data;
                        if (bytes == null) return const SizedBox();
                        return GestureDetector(
                          onTap: () => _onImageTap(asset),
                          child: Image.memory(bytes, fit: BoxFit.cover),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),

          SafeArea(
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "Pilih Foto",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }

}
