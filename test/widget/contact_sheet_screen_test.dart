import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/photo_filter.dart';
import 'package:photobooth/core/models/print_format.dart';
import 'package:photobooth/core/models/session_state.dart';
import 'package:photobooth/core/services/pose_prompt_engine.dart';
import 'package:photobooth/features/contact_sheet/screens/contact_sheet_screen.dart';
import 'package:photobooth/features/contact_sheet/widgets/shot_thumbnail_tile.dart';
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

    // Select 4 photos using ShotThumbnailTile
    final photoTiles = find.byType(ShotThumbnailTile);
    expect(photoTiles, findsWidgets);

    for (int i = 0; i < 4; i++) {
      await tester.tap(photoTiles.at(i));
      await tester.pump();
    }

    // Now Bake Strip is enabled
    expect(tester.widget<ElevatedButton>(bakeButtonFinder).enabled, isTrue);

    // Badges 1, 2, 3, 4 are visible
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('4'), findsWidgets);

    // Reorderable strip tray is displayed
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.textContaining('Strip Order'), findsOneWidget);
  });

  testWidgets('ContactSheetScreen renders filter chips and tapping updates controller filter with optimized shader passes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('filter_widget_');
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

    // Initial filter should be none (Original)
    expect((controller.state as SessionContactSheet).selectedFilter, equals(PhotoFilter.none));

    // For PhotoFilter.none, ColorFiltered should be omitted to avoid shader fragment overhead
    expect(find.byType(ColorFiltered), findsNothing);

    // Verify all filter chips are present
    for (final filter in PhotoFilter.values) {
      expect(find.byKey(ValueKey('filter_chip_${filter.name}')), findsOneWidget);
      expect(find.text(filter.displayName), findsOneWidget);
    }

    // Tap Haru Blue chip
    await tester.tap(find.byKey(const ValueKey('filter_chip_haruBlue')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedFilter, equals(PhotoFilter.haruBlue));

    // Verify ColorFiltered uses Haru Blue matrix
    var colorFilteredWidgets = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered));
    expect(colorFilteredWidgets.any((w) => w.colorFilter == ColorFilter.matrix(PhotoFilter.haruBlue.matrix)), isTrue);

    // Tap Warm Film chip
    await tester.tap(find.byKey(const ValueKey('filter_chip_warmFilm')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedFilter, equals(PhotoFilter.warmFilm));
    colorFilteredWidgets = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered));
    expect(colorFilteredWidgets.any((w) => w.colorFilter == ColorFilter.matrix(PhotoFilter.warmFilm.matrix)), isTrue);

    // Tap Film Noir chip
    await tester.tap(find.byKey(const ValueKey('filter_chip_mono')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedFilter, equals(PhotoFilter.mono));

    // Verify ColorFiltered uses Mono matrix
    colorFilteredWidgets = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered));
    expect(colorFilteredWidgets.any((w) => w.colorFilter == ColorFilter.matrix(PhotoFilter.mono.matrix)), isTrue);

    // Select a photo and verify strip tray also has ColorFiltered with selectedFilter
    final photoTiles = find.byType(ShotThumbnailTile);
    await tester.tap(photoTiles.first);
    await tester.pump();
    colorFilteredWidgets = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered));
    expect(colorFilteredWidgets.where((w) => w.colorFilter == ColorFilter.matrix(PhotoFilter.mono.matrix)).length, greaterThanOrEqualTo(2));

    // Return to Original (none) filter: ColorFiltered should be omitted again
    await tester.tap(find.byKey(const ValueKey('filter_chip_none')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedFilter, equals(PhotoFilter.none));
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('ContactSheetScreen renders print format buttons and tapping updates controller print format', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('format_widget_');
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

    // Initial print format should be singleStrip
    expect((controller.state as SessionContactSheet).selectedPrintFormat, equals(PrintFormat.singleStrip));

    // Verify format toggle buttons are present
    expect(find.byKey(const ValueKey('format_single')), findsOneWidget);
    expect(find.byKey(const ValueKey('format_twin')), findsOneWidget);
    expect(find.text('Single Strip'), findsOneWidget);
    expect(find.text('Twin Strip (1+1)'), findsOneWidget);

    // Tap Twin Strip format
    await tester.tap(find.byKey(const ValueKey('format_twin')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedPrintFormat, equals(PrintFormat.twinStrip));

    // Tap Single Strip format back
    await tester.tap(find.byKey(const ValueKey('format_single')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedPrintFormat, equals(PrintFormat.singleStrip));
  });

  testWidgets('ContactSheetScreen preserves selection invariance across filter and print format changes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('invariance_widget_');
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

    // Select 4 photos
    final photoTiles = find.byType(ShotThumbnailTile);
    await tester.tap(photoTiles.at(0));
    await tester.pump();
    await tester.tap(photoTiles.at(1));
    await tester.pump();
    await tester.tap(photoTiles.at(2));
    await tester.pump();
    await tester.tap(photoTiles.at(3));
    await tester.pump();

    final originalSelection = List<String>.from((controller.state as SessionContactSheet).selectedShotIds);
    expect(originalSelection.length, 4);

    // 1. Switch print format to twinStrip
    await tester.tap(find.byKey(const ValueKey('format_twin')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedShotIds, equals(originalSelection));

    // 2. Switch filter to Haru Blue
    await tester.tap(find.byKey(const ValueKey('filter_chip_haruBlue')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedShotIds, equals(originalSelection));

    // 3. Switch filter to Film Noir
    await tester.tap(find.byKey(const ValueKey('filter_chip_mono')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedShotIds, equals(originalSelection));

    // 4. Switch print format back to singleStrip
    await tester.tap(find.byKey(const ValueKey('format_single')));
    await tester.pump();
    expect((controller.state as SessionContactSheet).selectedShotIds, equals(originalSelection));

    // Badges 1, 2, 3, 4 remain visible and Bake Strip remains enabled
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    final bakeButtonFinder = find.widgetWithText(ElevatedButton, 'Bake Strip');
    expect(tester.widget<ElevatedButton>(bakeButtonFinder).enabled, isTrue);
  });

  testWidgets('ContactSheetScreen Retake button opens confirmation dialog and can retake or cancel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('retake_widget_');
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
    });

    await tester.pumpWidget(MaterialApp(
      home: ContactSheetScreen(controller: controller),
    ));

    expect(find.byKey(const ValueKey('retake_button')), findsOneWidget);

    // 1. Tap Retake -> Dialog appears
    await tester.tap(find.byKey(const ValueKey('retake_button')));
    await tester.pumpAndSettle();

    expect(find.text('Retake burst?'), findsOneWidget);

    // Tap Cancel in dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog closed, still on contact sheet
    expect(find.text('Retake burst?'), findsNothing);
    expect(controller.state, isA<SessionContactSheet>());

    // 2. Tap Retake again -> Confirm
    await tester.tap(find.byKey(const ValueKey('retake_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dialog_confirm_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Controller transitioned to SessionCountingDown for new burst
    expect(controller.state, isA<SessionCountingDown>());
  });

  testWidgets('ContactSheetScreen PopScope exit dialog cancels session on Exit', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('pop_sheet_widget_');
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
    });

    await tester.pumpWidget(MaterialApp(
      home: ContactSheetScreen(controller: controller),
    ));

    // Trigger back via PopScope
    final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
    popScope.onPopInvokedWithResult(false, null);
    await tester.pumpAndSettle();

    expect(find.text('Exit session?'), findsOneWidget);

    // Tap Exit
    await tester.tap(find.byKey(const ValueKey('exit_dialog_confirm_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.state, isA<SessionInitial>());
  });
}
