import 'package:flutter/material.dart';
import '../../../core/models/frame_template.dart';
import '../../../core/models/layout_type.dart';

class FrameCard extends StatelessWidget {
  final FrameTemplate frame;
  final LayoutType layout;
  final VoidCallback onTap;

  const FrameCard({
    super.key,
    required this.frame,
    required this.layout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(frame.backgroundColorValue);
    final isDark = bgColor.computeLuminance() < 0.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1.5,
                ),
              ),
              child: _buildSilhouettes(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            frame.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            frame.category,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSilhouettes() {
    final slotCount = layout.slotCount;
    if (layout == LayoutType.fourCut) {
      return Column(
        children: List.generate(slotCount, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(Icons.photo, color: Colors.white30, size: 16),
              ),
            ),
          );
        }),
      );
    } else if (layout == LayoutType.sixCut) {
      return Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    } else {
      return Center(
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(Icons.photo, color: Colors.white30, size: 28),
            ),
          ),
        ),
      );
    }
  }
}
