import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../core/config/app_constants.dart';
import '../../../core/models/captured_photo.dart';
import '../../../core/models/composite_job.dart';
import '../../../core/models/frame_template.dart';
import '../../../core/models/layout_type.dart';
import '../../../core/models/session_state.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/compositor_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/pose_prompt_engine.dart';
import '../../../core/services/storage_service.dart';

class BoothSessionController extends ValueNotifier<BoothSessionState> {
  final CameraService cameraService;
  final StorageService storageService;
  final FeedbackService feedbackService;
  final CompositorService compositorService;
  final PosePromptEngine poseEngine;

  String? _sessionId;
  Directory? _sessionDir;
  final List<CapturedPhoto> _capturedPhotos = [];
  Timer? _countdownTimer;

  BoothSessionController({
    required this.cameraService,
    required this.storageService,
    required this.feedbackService,
    required this.compositorService,
    required this.poseEngine,
    LayoutType initialLayout = LayoutType.fourCut,
  }) : super(SessionInitial(layout: initialLayout));

  BoothSessionState get state => value;
  Directory? get activeSessionDirectory => _sessionDir;
  String? get activeSessionId => _sessionId;

  bool get canConfirmSelection {
    final s = value;
    if (s is SessionContactSheet) {
      return s.selectedShotIds.length == s.layout.slotCount;
    }
    return false;
  }

  Future<void> startSession(
    LayoutType layout,
    FrameTemplate frame, {
    int countdownSeconds = AppConstants.defaultCountdownSeconds,
  }) async {
    _countdownTimer?.cancel();
    _capturedPhotos.clear();
    poseEngine.reset();

    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _sessionDir = await storageService.createSessionDirectory(_sessionId!);

    final prompt = poseEngine.nextPrompt();
    value = SessionCountingDown(
      layout: layout,
      frame: frame,
      currentShot: 1,
      secondsRemaining: countdownSeconds,
      posePrompt: prompt,
    );
  }

  Future<void> executeCaptureStep() async {
    final s = value;
    if (s is! SessionCountingDown && s is! SessionCapturing) return;

    final layout = (s is SessionCountingDown) ? s.layout : (s as SessionCapturing).layout;
    final frame = (s is SessionCountingDown) ? s.frame : (s as SessionCapturing).frame;
    final shotIndex = (s is SessionCountingDown) ? s.currentShot : (s as SessionCapturing).currentShot;
    final prompt = (s is SessionCountingDown) ? s.posePrompt : (s as SessionCapturing).posePrompt;

    value = SessionCapturing(
      layout: layout,
      frame: frame,
      currentShot: shotIndex,
      posePrompt: prompt,
    );

    // Multi-sensory feedback trigger
    await feedbackService.shutterCue();

    // Guard against cancellation before taking picture
    if (_sessionId == null || _sessionDir == null || value is! SessionCapturing) return;

    try {
      final filePath = await cameraService.takePicture(_sessionDir!.path);

      // Guard against cancellation after taking picture
      if (_sessionId == null || _sessionDir == null || value is! SessionCapturing) {
        final file = File(filePath);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
        return;
      }

      final photo = CapturedPhoto(
        id: 'shot_$shotIndex',
        filePath: filePath,
        timestamp: DateTime.now(),
        shotIndex: shotIndex,
      );
      _capturedPhotos.add(photo);

      if (shotIndex < layout.burstCount) {
        final nextPose = poseEngine.nextPrompt();
        value = SessionCountingDown(
          layout: layout,
          frame: frame,
          currentShot: shotIndex + 1,
          secondsRemaining: AppConstants.defaultCountdownSeconds,
          posePrompt: nextPose,
        );
      } else {
        // Completed all burst shots -> Contact sheet
        value = SessionContactSheet(
          layout: layout,
          frame: frame,
          allShots: List.unmodifiable(_capturedPhotos),
          selectedShotIds: const [],
        );
      }
    } catch (_) {
      // If session was cancelled during takePicture, safely ignore file write errors
      if (_sessionId == null || _sessionDir == null) return;
      rethrow;
    }
  }

  void selectShot(String photoId) {
    final s = value;
    if (s is! SessionContactSheet) return;

    final currentSelected = List<String>.from(s.selectedShotIds);
    if (currentSelected.contains(photoId)) {
      currentSelected.remove(photoId);
    } else {
      if (currentSelected.length < s.layout.slotCount) {
        currentSelected.add(photoId);
      }
    }

    value = s.copyWith(selectedShotIds: currentSelected);
  }

  void reorderSelectedShots(int oldIndex, int newIndex) {
    final s = value;
    if (s is! SessionContactSheet) return;

    final list = List<String>.from(s.selectedShotIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    value = s.copyWith(selectedShotIds: list);
  }

  Future<void> confirmSelection() async {
    final s = value;
    if (s is! SessionContactSheet || !canConfirmSelection) return;

    final layout = s.layout;
    final frame = s.frame;
    final selectedIds = s.selectedShotIds;

    value = SessionCompositing(layout: layout, frame: frame);

    // Map IDs to file paths in ordered sequence
    final photoMap = {for (var p in s.allShots) p.id: p.filePath};
    final selectedPaths = selectedIds.map((id) => photoMap[id]!).toList();

    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final outPath = p.join(_sessionDir!.path, 'composite_$_sessionId.png');

    final job = CompositeJob(
      photoPaths: selectedPaths,
      frame: frame,
      layout: layout,
      dateString: dateStr,
      outputPath: outPath,
    );

    final finalPath = await compositorService.renderStrip(job);
    value = SessionExportReady(
      layout: layout,
      frame: frame,
      compositeFilePath: finalPath,
    );
  }

  Future<void> retakeBurst() async {
    final s = value;
    if (s is! SessionContactSheet) return;

    final layout = s.layout;
    final frame = s.frame;

    if (_sessionId != null) {
      await storageService.clearSession(_sessionId!);
      _sessionDir = await storageService.createSessionDirectory(_sessionId!);
    }
    _capturedPhotos.clear();
    poseEngine.reset();

    final prompt = poseEngine.nextPrompt();
    value = SessionCountingDown(
      layout: layout,
      frame: frame,
      currentShot: 1,
      secondsRemaining: AppConstants.defaultCountdownSeconds,
      posePrompt: prompt,
    );
  }

  Future<void> cancelSession() async {
    _countdownTimer?.cancel();
    if (_sessionId != null) {
      await storageService.clearSession(_sessionId!);
    }
    _capturedPhotos.clear();
    _sessionDir = null;
    _sessionId = null;

    final currentLayout = switch (value) {
      SessionInitial s => s.layout,
      SessionCountingDown s => s.layout,
      SessionCapturing s => s.layout,
      SessionContactSheet s => s.layout,
      SessionCompositing s => s.layout,
      SessionExportReady s => s.layout,
    };

    value = SessionInitial(layout: currentLayout);
  }

  Future<void> finishSession() async {
    _countdownTimer?.cancel();
    if (_sessionId != null) {
      await storageService.finalizeSession(_sessionId!);
    }
    _capturedPhotos.clear();
    _sessionDir = null;
    _sessionId = null;

    final currentLayout = switch (value) {
      SessionInitial s => s.layout,
      SessionCountingDown s => s.layout,
      SessionCapturing s => s.layout,
      SessionContactSheet s => s.layout,
      SessionCompositing s => s.layout,
      SessionExportReady s => s.layout,
    };

    value = SessionInitial(layout: currentLayout);
  }

  @override
  Future<void> dispose() async {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
