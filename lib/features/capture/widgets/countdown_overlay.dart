import 'package:flutter/material.dart';

class CountdownOverlay extends StatelessWidget {
  final int secondsRemaining;

  const CountdownOverlay({
    super.key,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    if (secondsRemaining <= 0) return const SizedBox.shrink();

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          '$secondsRemaining',
          key: ValueKey<int>(secondsRemaining),
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w900,
            color: secondsRemaining == 1 ? const Color(0xFFFF5252) : Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
