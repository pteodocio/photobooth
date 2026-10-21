import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/services/pose_prompt_engine.dart';
import 'package:photobooth/features/contact_sheet/screens/contact_sheet_screen.dart';
import 'package:photobooth/features/session/controllers/booth_session_controller.dart';
import 'package:photobooth/services/compositor_service_impl.dart';
import 'package:photobooth/services/feedback_service_impl.dart';
import 'package:photobooth/services/mock_camera_service.dart';
import 'package:photobooth/services/storage_service_impl.dart';

void main() {
  testWidgets('ContactSheetScreen renders thumbnails and enforces selection of N', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('sheet_widget_');
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
      for (int i = 1; i <= 6; i++) {
        await controller.executeCaptureStep();
      }
    });

    await tester.pumpWidget(MaterialApp(
      home: ContactSheetScreen(controller: controller),
    ));

    expect(find.text('Select 4 photos'), findsOneWidget);
    expect(find.text('Bake Strip'), findsOneWidget);

    // Initial state: Bake Strip button disabled
    final bakeButtonFinder = find.widgetWithText(ElevatedButton, 'Bake Strip');
    expect(tester.widget<ElevatedButton>(bakeButtonFinder).enabled, isFalse);

    // Select 4 photos
    final inkWells = find.byType(InkWell);
    expect(inkWells, findsWidgets);

    for (int i = 0; i < 4; i++) {
      await tester.tap(inkWells.at(i));
      await tester.pump();
    }

    // Now Bake Strip is enabled
    expect(tester.widget<ElevatedButton>(bakeButtonFinder).enabled, isTrue);

    // Badges 1, 2, 3, 4 are visible
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
