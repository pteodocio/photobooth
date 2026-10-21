import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../core/services/camera_service.dart';

class MockCameraService implements CameraService {
  bool _initialized = false;
  CameraLensDirection _direction = CameraLensDirection.back;
  int _shotCounter = 0;

  @override
  bool get isInitialized => _initialized;

  @override
  CameraLensDirection get currentDirection => _direction;

  @override
  Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back}) async {
    _direction = preferredDirection;
    _initialized = true;
  }

  @override
  Future<void> switchCamera() async {
    _direction = _direction == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }

  @override
  Widget buildPreview() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _direction == CameraLensDirection.front
                  ? Icons.camera_front
                  : Icons.camera_rear,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Mock Camera Preview (${_direction.name})',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<String> takePicture(String destinationDirectory) async {
    _shotCounter++;
    final image = img.Image(width: 200, height: 150);
    final r = (_shotCounter * 45) % 255;
    final g = (_shotCounter * 75) % 255;
    final b = (_shotCounter * 115) % 255;
    img.fill(image, color: img.ColorRgb8(r, g, b));

    final bytes = img.encodeJpg(image);
    final fileName = 'shot_${DateTime.now().millisecondsSinceEpoch}_$_shotCounter.jpg';
    final filePath = p.join(destinationDirectory, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
