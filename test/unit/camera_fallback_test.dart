import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/services/camera_service.dart';
import 'package:photobooth/services/camera_service_impl.dart';
import 'package:photobooth/services/mock_camera_service.dart';

Future<CameraService> resolveCameraService({CameraService? initialCamera}) async {
  CameraService cameraService = initialCamera ?? CameraServiceImpl();
  try {
    await cameraService.initialize();
  } catch (_) {}

  if (!cameraService.isInitialized) {
    cameraService = MockCameraService();
    await cameraService.initialize();
  }
  return cameraService;
}

void main() {
  test('resolveCameraService falls back to MockCameraService when camera unavailable', () async {
    final failingCamera = FailingCameraService();
    final resolved = await resolveCameraService(initialCamera: failingCamera);
    expect(resolved, isA<MockCameraService>());
    expect(resolved.isInitialized, isTrue);
  });
}

class FailingCameraService implements CameraService {
  @override
  bool get isInitialized => false;

  @override
  CameraLensDirection get currentDirection => CameraLensDirection.back;

  @override
  Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back}) async {
    // Simulates empty availableCameras() or exception on headless device
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
