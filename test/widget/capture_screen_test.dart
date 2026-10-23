import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/session_state.dart';
import 'package:photobooth/core/services/pose_prompt_engine.dart';
import 'package:photobooth/features/capture/screens/capture_screen.dart';
import 'package:photobooth/features/session/controllers/booth_session_controller.dart';
import 'package:photobooth/services/compositor_service_impl.dart';
import 'package:photobooth/services/feedback_service_impl.dart';
import 'package:photobooth/services/mock_camera_service.dart';
import 'package:photobooth/services/storage_service_impl.dart';

void main() {
  testWidgets('CaptureScreen displays camera preview, countdown, pose prompt, and cancel button', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('capture_test_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final controller = BoothSessionController(
      cameraService: MockCameraService(),
      storageService: StorageServiceImpl(baseDirectoryOverride: tempDir),
      feedbackService: FeedbackServiceImpl(enableAudio: false, enableHaptics: false),
      compositorService: CompositorServiceImpl(),
      poseEngine: PosePromptEngine(),
    );

    await tester.runAsync(() async {
      await controller.cameraService.initialize();
      await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    });

    await tester.pumpWidget(MaterialApp(
      home: CaptureScreen(controller: controller),
    ));

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.textContaining('Shot 1 of 6'), findsOneWidget);

    final promptState = controller.state as SessionCountingDown;
    expect(find.text(promptState.posePrompt), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('cancel_capture_button')));
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(controller.state, isA<SessionInitial>());
  });

  testWidgets('CaptureScreen flip camera button switches lens direction', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('capture_flip_test_');
    addTearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    final mockCamera = MockCameraService();
    final controller = BoothSessionController(
      cameraService: mockCamera,
      storageService: StorageServiceImpl(baseDirectoryOverride: tempDir),
      feedbackService: FeedbackServiceImpl(enableAudio: false, enableHaptics: false),
      compositorService: CompositorServiceImpl(),
      poseEngine: PosePromptEngine(),
    );

    await tester.runAsync(() async {
      await controller.cameraService.initialize();
      await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    });

    await tester.pumpWidget(MaterialApp(
      home: CaptureScreen(controller: controller),
    ));

    expect(find.byKey(const ValueKey('flip_camera_button')), findsOneWidget);
    expect(find.textContaining('Mock Camera Preview (back)'), findsOneWidget);

    // Tap flip camera
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('flip_camera_button')));
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.textContaining('Mock Camera Preview (front)'), findsOneWidget);
  });

  testWidgets('CaptureScreen PopScope cancels session on system back', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('capture_pop_test_');
    addTearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    final controller = BoothSessionController(
      cameraService: MockCameraService(),
      storageService: StorageServiceImpl(baseDirectoryOverride: tempDir),
      feedbackService: FeedbackServiceImpl(enableAudio: false, enableHaptics: false),
      compositorService: CompositorServiceImpl(),
      poseEngine: PosePromptEngine(),
    );

    await tester.runAsync(() async {
      await controller.cameraService.initialize();
      await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    });

    await tester.pumpWidget(MaterialApp(
      home: CaptureScreen(controller: controller),
    ));

    expect(controller.state, isA<SessionCountingDown>());

    // Trigger back via PopScope
    final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
    await tester.runAsync(() async {
      popScope.onPopInvokedWithResult(false, null);
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(controller.state, isA<SessionInitial>());
  });
}
