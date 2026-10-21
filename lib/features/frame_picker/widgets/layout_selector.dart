import 'package:flutter/material.dart';
import '../../../core/models/layout_type.dart';

class LayoutSelector extends StatelessWidget {
  final LayoutType selectedLayout;
  final ValueChanged<LayoutType> onLayoutChanged;

  const LayoutSelector({
    super.key,
    required this.selectedLayout,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: LayoutType.values.map((layout) {
          final isSelected = layout == selectedLayout;
          return GestureDetector(
            onTap: () => onLayoutChanged(layout),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                layout.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
