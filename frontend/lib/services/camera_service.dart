// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img;

// class CameraService {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   bool _isInitialized = false;

//   Future<bool> initialize() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras == null || _cameras!.isEmpty) return false;

//       _controller = CameraController(
//         _cameras!.first,
//         ResolutionPreset.high,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg,
//       );

//       await _controller!.initialize();
//       _isInitialized = true;
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   CameraController? get controller => _controller;
//   bool get isInitialized => _isInitialized;

//   Future<File?> capturePhoto() async {
//     if (!_isInitialized || _controller == null) return null;
//     final file = await _controller!.takePicture();
//     return File(file.path);
//   }

//   Future<File?> captureAndCompressPhoto({
//     int maxWidth = 1280,
//     int quality = 85,
//   }) async {
//     final original = await capturePhoto();
//     if (original == null) return null;

//     final bytes = await original.readAsBytes();
//     var image = img.decodeImage(bytes);
//     if (image == null) return original;

//     if (image.width > maxWidth) {
//       image = img.copyResize(image, width: maxWidth);
//     }

//     final out = img.encodeJpg(image, quality: quality);

//     final dir = await getTemporaryDirectory();
//     final path =
//         '${dir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

//     final file = File(path);
//     await file.writeAsBytes(out);
//     await original.delete();

//     return file;
//   }

//   /// GPS metadata (NO-OP)
//   /// package:image cannot write GPS EXIF (read-only limitation)
//   Future<File> addGPSMetadata({
//     required File photoFile,
//     required double latitude,
//     required double longitude,
//   }) async {
//     // Feature preserved intentionally.
//     // Use native Android/iOS EXIF writers if GPS is required.
//     return photoFile;
//   }

//   Future<File> addTimestampWatermark(File photoFile) async {
//     try {
//       final bytes = await photoFile.readAsBytes();
//       final image = img.decodeImage(bytes);
//       if (image == null) return photoFile;

//       final now = DateTime.now();
//       final text =
//           '${now.day}/${now.month}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

//       img.drawString(
//         image,
//         text,
//         font: img.arial14,
//         x: 10,
//         y: image.height - 24,
//         color: img.ColorRgb8(255, 255, 255),
//       );

//       final out = img.encodeJpg(image);
//       await photoFile.writeAsBytes(out);

//       return photoFile;
//     } catch (_) {
//       return photoFile;
//     }
//   }

//   Future<void> switchCamera() async {
//     if (_cameras == null || _cameras!.length < 2) return;

//     final current = _controller!.description;
//     final next =
//         _cameras!.firstWhere((c) => c.lensDirection != current.lensDirection);

//     await _controller!.dispose();

//     _controller = CameraController(
//       next,
//       ResolutionPreset.high,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );

//     await _controller!.initialize();
//   }

//   void dispose() {
//     _controller?.dispose();
//     _isInitialized = false;
//   }

//   int get cameraCount => _cameras?.length ?? 0;
//   bool get hasMultipleCameras => cameraCount > 1;
// }
// lib/services/camera_service.dart
// NEW SERVICE: Handle camera for visit photos (prevents gallery uploads)
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return false;

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<File?> capturePhoto() async {
    if (!_isInitialized || _controller == null) return null;
    final file = await _controller!.takePicture();
    return File(file.path);
  }

  Future<File?> captureAndCompressPhoto({
    int maxWidth = 1280,
    int quality = 85,
  }) async {
    final original = await capturePhoto();
    if (original == null) return null;

    final bytes = await original.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) return original;

    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }

    final out = img.encodeJpg(image, quality: quality);

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final file = File(path);
    await file.writeAsBytes(out);
    await original.delete();

    return file;
  }

  /// GPS metadata (NOT supported in image 4.x)
  Future<File> addGPSMetadata({
    required File photoFile,
    required double latitude,
    required double longitude,
  }) async {
    return photoFile;
  }

  Future<File> addTimestampWatermark(File photoFile) async {
    final bytes = await photoFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return photoFile;

    final now = DateTime.now();
    final text =
        '${now.day}/${now.month}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    img.drawString(
      image,
      text,
      font: img.arial14,
      x: 10,
      y: image.height - 24,
      color: img.ColorRgb8(255, 255, 255),
    );

    final out = img.encodeJpg(image);
    await photoFile.writeAsBytes(out);
    return photoFile;
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final current = _controller!.description;
    final next =
        _cameras!.firstWhere((c) => c.lensDirection != current.lensDirection);

    await _controller!.dispose();

    _controller = CameraController(
      next,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }

  int get cameraCount => _cameras?.length ?? 0;
  bool get hasMultipleCameras => cameraCount > 1;
}
