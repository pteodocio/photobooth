import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';

class FlashOverlay extends StatelessWidget {
  final bool isFlashing;

  const FlashOverlay({
    super.key,
    required this.isFlashing,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isFlashing ? AppConstants.flashOpacity : 0.0,
        duration: const Duration(milliseconds: AppConstants.flashDurationMs),
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }
}
