import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/photo_filter.dart';
import 'package:photobooth/core/models/print_format.dart';
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

  test('Complete authentic Korean 4-cut photobooth flow with Haru Blue and Twin Strip (1+1)', () async {
    final tempDir = Directory.systemTemp.createTempSync('e2e_twin_haru_test_');
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

    // 1. Start session with fourCut layout and frame
    await controller.cameraService.initialize();
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    expect(controller.state, isA<SessionCountingDown>());

    // 2. Execute 6 capture steps
    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }
    expect(controller.state, isA<SessionContactSheet>());
    final sheet = controller.state as SessionContactSheet;
    expect(sheet.allShots.length, 6);

    // 3. Set filter to PhotoFilter.haruBlue
    controller.setFilter(PhotoFilter.haruBlue);
    expect((controller.state as SessionContactSheet).selectedFilter, PhotoFilter.haruBlue);

    // 4. Set print format to PrintFormat.twinStrip
    controller.setPrintFormat(PrintFormat.twinStrip);
    expect((controller.state as SessionContactSheet).selectedPrintFormat, PrintFormat.twinStrip);

    // 5. Select 4 shots
    for (int i = 0; i < 4; i++) {
      controller.selectShot(sheet.allShots[i].id);
    }
    expect(controller.canConfirmSelection, isTrue);

    // Keep reference to session dir to verify cleanup after finishSession
    final sessionDir = controller.activeSessionDirectory!;
    expect(sessionDir.existsSync(), isTrue);

    // 6. Confirm selection
    await controller.confirmSelection();
    expect(controller.state, isA<SessionExportReady>());

    // 7. Verify state is SessionExportReady with printFormat == PrintFormat.twinStrip
    final exportState = controller.state as SessionExportReady;
    expect(exportState.printFormat, PrintFormat.twinStrip);

    // 8. Read composite file with package:image and verify dimensions are 2400 x 3600
    final compositeFile = File(exportState.compositeFilePath);
    expect(compositeFile.existsSync(), isTrue);
    final bytes = await compositeFile.readAsBytes();
    final decodedImage = img.decodePng(bytes);
    expect(decodedImage, isNotNull);
    expect(decodedImage!.width, 2400);
    expect(decodedImage.height, 3600);

    // 9. Finish session and verify cleanup (all burst photos and composite deleted from session directory)
    await controller.finishSession();
    expect(controller.state, isA<SessionInitial>());
    expect(sessionDir.existsSync(), isFalse);
    expect(compositeFile.existsSync(), isFalse);
  });
}
