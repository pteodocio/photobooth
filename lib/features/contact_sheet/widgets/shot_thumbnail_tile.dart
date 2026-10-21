import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/captured_photo.dart';

class ShotThumbnailTile extends StatelessWidget {
  final CapturedPhoto photo;
  final int? selectionOrder; // 1-based index, or null if unselected
  final ColorFilter? colorFilter;
  final VoidCallback onTap;

  const ShotThumbnailTile({
    super.key,
    required this.photo,
    required this.selectionOrder,
    this.colorFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectionOrder != null;

    Widget imageWidget = Image.file(
      File(photo.filePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.white54),
      ),
    );

    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: colorFilter!,
        child: imageWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF5252) : Colors.white24,
              width: isSelected ? 3.0 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSelected ? 9 : 11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo image with filter applied strictly to pixels
                imageWidget,

                // Translucent dim when unselected
                if (!isSelected)
                  Container(
                    color: Colors.black.withAlpha(40),
                  ),

                // Selection Number Badge
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$selectionOrder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
