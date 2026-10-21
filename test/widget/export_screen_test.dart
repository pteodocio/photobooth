import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/print_format.dart';
import 'package:photobooth/core/models/session_state.dart';
import 'package:photobooth/core/services/pose_prompt_engine.dart';
import 'package:photobooth/features/export/screens/export_screen.dart';
import 'package:photobooth/features/session/controllers/booth_session_controller.dart';
import 'package:photobooth/services/compositor_service_impl.dart';
import 'package:photobooth/services/feedback_service_impl.dart';
import 'package:photobooth/services/mock_camera_service.dart';
import 'package:photobooth/services/storage_service_impl.dart';

void main() {
  testWidgets('ExportScreen renders singleStrip with aspect ratio 1/3, chip, action buttons and finishes session', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('export_widget_single_');
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
      for (int i = 1; i <= 6; i++) {
        await controller.executeCaptureStep();
      }
      final sheet = controller.state;
      if (sheet is! SessionContactSheet) return;
      for (int i = 0; i < 4; i++) {
        controller.selectShot(sheet.allShots[i].id);
      }
      await controller.confirmSelection();
    });

    await tester.pumpWidget(MaterialApp(
      home: ExportScreen(controller: controller),
    ));

    expect(find.text('Your Film Strip'), findsOneWidget);
    expect(find.text('Single Strip'), findsOneWidget);

    final aspectRatioFinder = find.byType(AspectRatio);
    expect(aspectRatioFinder, findsOneWidget);
    final aspectRatio = tester.widget<AspectRatio>(aspectRatioFinder);
    expect(aspectRatio.aspectRatio, closeTo(1 / 3, 0.001));

    expect(find.text('Save to Roll'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Done & New Session'), findsOneWidget);

    // Tap Done inside runAsync to allow async finalizeSession to execute
    await tester.runAsync(() async {
      await tester.tap(find.text('Done & New Session'));
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(controller.state, isA<SessionInitial>());
  });

  testWidgets('ExportScreen renders twinStrip with aspect ratio 2/3 and format chip', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('export_widget_twin_');
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
      for (int i = 1; i <= 6; i++) {
        await controller.executeCaptureStep();
      }
      final sheet = controller.state;
      if (sheet is! SessionContactSheet) return;
      controller.setPrintFormat(PrintFormat.twinStrip);
      for (int i = 0; i < 4; i++) {
        controller.selectShot(sheet.allShots[i].id);
      }
      await controller.confirmSelection();
    });

    await tester.pumpWidget(MaterialApp(
      home: ExportScreen(controller: controller),
    ));

    expect(find.text('Your Film Strip'), findsOneWidget);
    expect(find.text('Twin Strip (1+1)'), findsOneWidget);

    final aspectRatioFinder = find.byType(AspectRatio);
    expect(aspectRatioFinder, findsOneWidget);
    final aspectRatio = tester.widget<AspectRatio>(aspectRatioFinder);
    expect(aspectRatio.aspectRatio, closeTo(2 / 3, 0.001));
  });
}
