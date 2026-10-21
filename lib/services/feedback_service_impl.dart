import 'package:flutter/services.dart';
import '../core/services/feedback_service.dart';

class FeedbackServiceImpl implements FeedbackService {
  final bool enableAudio;
  final bool enableHaptics;

  FeedbackServiceImpl({
    this.enableAudio = true,
    this.enableHaptics = true,
  });

  @override
  Future<void> countdownTick() async {
    if (enableHaptics) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (enableAudio) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  @override
  Future<void> countdownFinalBeep() async {
    if (enableHaptics) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (enableAudio) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  @override
  Future<void> shutterCue() async {
    if (enableHaptics) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (enableAudio) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }
}
