import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../core/services/camera_service.dart';

class CameraServiceImpl implements CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized && _controller != null && _controller!.value.isInitialized;

  @override
  CameraLensDirection get currentDirection {
    if (_cameras.isEmpty || _selectedCameraIndex >= _cameras.length) {
      return CameraLensDirection.back;
    }
    return _cameras[_selectedCameraIndex].lensDirection;
  }

  @override
  Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _initialized = false;
        return;
      }

      int targetIndex = _cameras.indexWhere((c) => c.lensDirection == preferredDirection);
      if (targetIndex == -1) {
        targetIndex = 0; // Fallback to first available camera
      }
      _selectedCameraIndex = targetIndex;

      await _startController(_cameras[_selectedCameraIndex]);
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _startController(CameraDescription cameraDescription) async {
    _initialized = false;
    final prevController = _controller;
    if (prevController != null) {
      try {
        await prevController.dispose();
      } catch (_) {}
    }

    try {
      final newController = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = newController;
      await newController.initialize();
      await newController.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_cameras.length <= 1) return;

    final prevIndex = _selectedCameraIndex;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    try {
      await _startController(_cameras[_selectedCameraIndex]);
    } catch (_) {
      _selectedCameraIndex = prevIndex;
    }
  }

  @override
  Widget buildPreview() {
    if (!isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }
    return CameraPreview(_controller!);
  }

  @override
  Future<String> takePicture(String destinationDirectory) async {
    if (!isInitialized || _controller == null) {
      throw StateError('Camera is not initialized');
    }
    final xFile = await _controller!.takePicture();
    final fileName = 'shot_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destinationPath = p.join(destinationDirectory, fileName);
    await xFile.saveTo(destinationPath);
    return destinationPath;
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    await _controller?.dispose();
    _controller = null;
  }
}
