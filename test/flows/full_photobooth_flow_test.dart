import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/session_state.dart';
import 'package:photobooth/core/services/pose_prompt_engine.dart';
import 'package:photobooth/features/session/controllers/booth_session_controller.dart';
import 'package:photobooth/services/compositor_service_impl.dart';
import 'package:photobooth/services/feedback_service_impl.dart';
import 'package:photobooth/services/mock_camera_service.dart';
import 'package:photobooth/services/storage_service_impl.dart';

void main() {
  test('Complete photobooth flow: Frame -> 6-Shot Burst -> Select 4 -> Composite -> Export Ready -> Finish', () async {
    final tempDir = Directory.systemTemp.createTempSync('e2e_test_');
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

    // 1. Start session
    await controller.cameraService.initialize();
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    expect(controller.state, isA<SessionCountingDown>());

    // 2. Burst capture 6 shots
    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }
    expect(controller.state, isA<SessionContactSheet>());
    final sheet = controller.state as SessionContactSheet;
    expect(sheet.allShots.length, 6);

    // 3. Select 4 shots
    for (int i = 0; i < 4; i++) {
      controller.selectShot(sheet.allShots[i].id);
    }
    expect(controller.canConfirmSelection, isTrue);

    // 4. Confirm & Bake Strip
    await controller.confirmSelection();
    expect(controller.state, isA<SessionExportReady>());

    final exportState = controller.state as SessionExportReady;
    final compositeFile = File(exportState.compositeFilePath);
    expect(compositeFile.existsSync(), isTrue);
    expect(compositeFile.lengthSync(), greaterThan(1000));

    // 5. Finish session cleans up raw files
    await controller.finishSession();
    expect(controller.state, isA<SessionInitial>());
  });
}
