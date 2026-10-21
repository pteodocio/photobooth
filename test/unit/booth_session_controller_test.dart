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
  late Directory tempDir;
  late BoothSessionController controller;
  late MockCameraService mockCamera;
  late StorageServiceImpl storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('controller_test_');
    mockCamera = MockCameraService();
    storage = StorageServiceImpl(baseDirectoryOverride: tempDir);
    controller = BoothSessionController(
      cameraService: mockCamera,
      storageService: storage,
      feedbackService: FeedbackServiceImpl(enableAudio: false, enableHaptics: false),
      compositorService: CompositorServiceImpl(),
      poseEngine: PosePromptEngine(),
    );
  });

  tearDown(() async {
    await controller.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('full burst capture of 6 shots advances to ContactSheet', () async {
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    expect(controller.state, isA<SessionCountingDown>());

    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }

    expect(controller.state, isA<SessionContactSheet>());
    final sheet = controller.state as SessionContactSheet;
    expect(sheet.allShots.length, 6);
  });

  test('confirmSelection requires exactly N shots for fourCut', () async {
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }

    final sheet = controller.state as SessionContactSheet;
    // 0 selected
    expect(controller.canConfirmSelection, isFalse);

    // 3 selected
    controller.selectShot(sheet.allShots[0].id);
    controller.selectShot(sheet.allShots[1].id);
    controller.selectShot(sheet.allShots[2].id);
    expect(controller.canConfirmSelection, isFalse);

    // 4th selected
    controller.selectShot(sheet.allShots[3].id);
    expect(controller.canConfirmSelection, isTrue);

    // 5th attempt ignored
    controller.selectShot(sheet.allShots[4].id);
    final updatedSheet = controller.state as SessionContactSheet;
    expect(updatedSheet.selectedShotIds.length, 4);

    // Deselect
    controller.selectShot(sheet.allShots[3].id);
    expect(controller.canConfirmSelection, isFalse);
  });

  test('reorder selected shots updates order', () async {
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }
    final sheet = controller.state as SessionContactSheet;
    controller.selectShot(sheet.allShots[0].id);
    controller.selectShot(sheet.allShots[1].id);
    controller.selectShot(sheet.allShots[2].id);
    controller.selectShot(sheet.allShots[3].id);

    controller.reorderSelectedShots(0, 3);
    final reorderedSheet = controller.state as SessionContactSheet;
    expect(reorderedSheet.selectedShotIds.first, sheet.allShots[1].id);
  });

  test('confirmSelection renders composite and transitions to ExportReady', () async {
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }
    final sheet = controller.state as SessionContactSheet;
    for (int i = 0; i < 4; i++) {
      controller.selectShot(sheet.allShots[i].id);
    }

    await controller.confirmSelection();
    expect(controller.state, isA<SessionExportReady>());
    final exportReady = controller.state as SessionExportReady;
    expect(File(exportReady.compositeFilePath).existsSync(), isTrue);
  });

  test('cancelSession purges directory and returns to SessionInitial', () async {
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    await controller.executeCaptureStep();
    expect(controller.activeSessionDirectory, isNotNull);
    final sessionPath = controller.activeSessionDirectory!.path;
    expect(Directory(sessionPath).existsSync(), isTrue);

    await controller.cancelSession();
    expect(controller.state, isA<SessionInitial>());
    expect(Directory(sessionPath).existsSync(), isFalse);
  });

  test('retakeBurst deletes current shots and restarts at shot 1', () async {
    await controller.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);
    for (int i = 1; i <= 6; i++) {
      await controller.executeCaptureStep();
    }
    expect(controller.state, isA<SessionContactSheet>());

    await controller.retakeBurst();
    expect(controller.state, isA<SessionCountingDown>());
    final countdown = controller.state as SessionCountingDown;
    expect(countdown.currentShot, 1);
  });

  test('cancelSession during in-flight capture step does not resurrect session', () async {
    final delayedCamera = DelayedMockCameraService(delay: const Duration(milliseconds: 80));
    final raceController = BoothSessionController(
      cameraService: delayedCamera,
      storageService: storage,
      feedbackService: FeedbackServiceImpl(enableAudio: false, enableHaptics: false),
      compositorService: CompositorServiceImpl(),
      poseEngine: PosePromptEngine(),
    );
    await raceController.startSession(LayoutType.fourCut, FrameTemplate.bundledFrames.first);

    // Start capture asynchronously
    final captureFuture = raceController.executeCaptureStep();
    // Cancel session immediately while takePicture is in-flight
    await raceController.cancelSession();
    expect(raceController.state, isA<SessionInitial>());

    await captureFuture;
    // Must remain in SessionInitial, NOT resurrected to SessionCountingDown
    expect(raceController.state, isA<SessionInitial>());
  });
}

class DelayedMockCameraService extends MockCameraService {
  final Duration delay;
  DelayedMockCameraService({required this.delay});

  @override
  Future<String> takePicture(String destinationDirectory) async {
    await Future.delayed(delay);
    return await super.takePicture(destinationDirectory);
  }
}

