import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

abstract class CameraService {
  Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back});
  Widget buildPreview();
  Future<void> switchCamera();
  Future<String> takePicture(String destinationDirectory);
  CameraLensDirection get currentDirection;
  bool get isInitialized;
  Future<void> dispose();
}
