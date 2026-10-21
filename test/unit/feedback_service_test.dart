import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/services/feedback_service_impl.dart';

void main() {
  test('FeedbackService runs haptic and audio triggers without unhandled exceptions', () async {
    final service = FeedbackServiceImpl(enableAudio: false, enableHaptics: false);
    await service.countdownTick();
    await service.countdownFinalBeep();
    await service.shutterCue();
    expect(true, isTrue);
  });
}
