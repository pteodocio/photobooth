import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/pose_prompt_engine.dart';
import 'features/session/controllers/booth_session_controller.dart';
import 'services/camera_service_impl.dart';
import 'services/compositor_service_impl.dart';
import 'services/feedback_service_impl.dart';
import 'services/storage_service_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageServiceImpl();
  // Clear any dangling temp directories from previous sessions
  await storageService.cleanupOrphanedSessions();

  final cameraService = CameraServiceImpl();
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

  // Initialize camera service eagerly
  await cameraService.initialize();

  runApp(PhotoboothApp(controller: controller));
}
