import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/session_state.dart';
import '../../session/controllers/booth_session_controller.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/flash_overlay.dart';
import '../widgets/pose_prompt_card.dart';

class CaptureScreen extends StatefulWidget {
  final BoothSessionController controller;
  final bool autoTick;

  const CaptureScreen({
    super.key,
    required this.controller,
    this.autoTick = false,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  Timer? _countdownTimer;
  int _secondsLeft = 3;

  @override
  void initState() {
    super.initState();
    if (widget.autoTick) {
      _startAutoCountdown();
    }
  }

  void _startAutoCountdown() {
    _countdownTimer?.cancel();
    _secondsLeft = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsLeft > 1) {
        if (!mounted) return;
        setState(() {
          _secondsLeft--;
        });
        await widget.controller.feedbackService.countdownTick();
      } else {
        timer.cancel();
        await widget.controller.feedbackService.countdownFinalBeep();
        if (!mounted) return;
        await widget.controller.executeCaptureStep();
        if (mounted && widget.controller.state is SessionCountingDown) {
          _startAutoCountdown();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BoothSessionState>(
      valueListenable: widget.controller,
      builder: (context, state, child) {
        final currentShot = switch (state) {
          SessionCountingDown s => s.currentShot,
          SessionCapturing s => s.currentShot,
          _ => 1,
        };
        final totalShots = switch (state) {
          SessionCountingDown s => s.layout.burstCount,
          SessionCapturing s => s.layout.burstCount,
          _ => 6,
        };
        final posePrompt = switch (state) {
          SessionCountingDown s => s.posePrompt,
          SessionCapturing s => s.posePrompt,
          _ => '',
        };
        final secondsRemaining = switch (state) {
          SessionCountingDown s => widget.autoTick ? _secondsLeft : s.secondsRemaining,
          _ => 0,
        };
        final isFlashing = state is SessionCapturing;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            _countdownTimer?.cancel();
            await widget.controller.cancelSession();
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Camera Preview
                Center(
                  child: widget.controller.cameraService.buildPreview(),
                ),

                // 2. Flash Overlay
                FlashOverlay(isFlashing: isFlashing),

                // 3. UI Controls and Overlay
                SafeArea(
                  child: Column(
                    children: [
                      // Top App Bar Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              key: const ValueKey('cancel_capture_button'),
                              icon: const Icon(Icons.close, color: Colors.white, size: 28),
                              onPressed: () async {
                                _countdownTimer?.cancel();
                                await widget.controller.cancelSession();
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Shot $currentShot of $totalShots',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('flip_camera_button'),
                              icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 26),
                              onPressed: () async {
                                try {
                                  await widget.controller.cameraService.switchCamera();
                                } catch (_) {}
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),
                    // Pose Prompt Banner
                    PosePromptCard(posePrompt: posePrompt),

                    // Center Countdown
                    Expanded(
                      child: CountdownOverlay(secondsRemaining: secondsRemaining),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}
