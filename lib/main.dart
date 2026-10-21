import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/camera_service.dart';
import 'core/services/pose_prompt_engine.dart';
import 'features/session/controllers/booth_session_controller.dart';
import 'services/camera_service_impl.dart';
import 'services/compositor_service_impl.dart';
import 'services/feedback_service_impl.dart';
import 'services/mock_camera_service.dart';
import 'services/storage_service_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageServiceImpl();
  // Clear any dangling temp directories from previous sessions
  await storageService.cleanupOrphanedSessions();

  CameraService cameraService = CameraServiceImpl();
  try {
    await cameraService.initialize();
  } catch (_) {}

  // Seamless fallback to MockCameraService if physical camera hardware is absent
  if (!cameraService.isInitialized) {
    cameraService = MockCameraService();
    await cameraService.initialize();
  }

  final feedbackService = FeedbackServiceImpl();
  final compositorService = CompositorServiceImpl();
  final poseEngine = PosePromptEngine();

  final controller = BoothSessionController(
    cameraService: cameraService,
    storageService: storageService,
    feedbackService: feedbackService,
    compositorService: compositorService,
    poseEngine: poseEngine,
  );

  runApp(PhotoboothApp(controller: controller));
}
