import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/services/mock_camera_service.dart';

void main() {
  test('MockCameraService initializes, switches camera, and takes picture', () async {
    final mockCamera = MockCameraService();
    expect(mockCamera.isInitialized, isFalse);

    await mockCamera.initialize();
    expect(mockCamera.isInitialized, isTrue);
    expect(mockCamera.currentDirection, CameraLensDirection.back);

    await mockCamera.switchCamera();
    expect(mockCamera.currentDirection, CameraLensDirection.front);

    final previewWidget = mockCamera.buildPreview();
    expect(previewWidget, isNotNull);

    final tempDir = await Directory.systemTemp.createTemp('mock_cam_');
    final shotPath = await mockCamera.takePicture(tempDir.path);
    final shotFile = File(shotPath);
    expect(await shotFile.exists(), isTrue);
    expect(await shotFile.length(), greaterThan(0));

    await tempDir.delete(recursive: true);
    await mockCamera.dispose();
    expect(mockCamera.isInitialized, isFalse);
  });
}
