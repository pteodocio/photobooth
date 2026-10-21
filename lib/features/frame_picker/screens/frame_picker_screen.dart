import 'package:flutter/material.dart';
import '../../../core/models/frame_template.dart';
import '../../../core/models/layout_type.dart';
import '../widgets/frame_card.dart';
import '../widgets/layout_selector.dart';

class FramePickerScreen extends StatefulWidget {
  final LayoutType initialLayout;
  final void Function(LayoutType layout, FrameTemplate frame)? onFrameSelected;

  const FramePickerScreen({
    super.key,
    this.initialLayout = LayoutType.fourCut,
    this.onFrameSelected,
  });

  @override
  State<FramePickerScreen> createState() => _FramePickerScreenState();
}

class _FramePickerScreenState extends State<FramePickerScreen> {
  late LayoutType _currentLayout;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _currentLayout = widget.initialLayout;
  }

  @override
  Widget build(BuildContext context) {
    final allFrames = FrameTemplate.bundledFrames;
    final categories = [
      'All',
      ...{for (final f in allFrames) f.category},
    ];

    final filteredFrames = _selectedCategory == 'All'
        ? allFrames
        : allFrames.where((f) => f.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              '인생네컷',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'Korean 4-Cut Photobooth',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            LayoutSelector(
              selectedLayout: _currentLayout,
              onLayoutChanged: (layout) {
                setState(() {
                  _currentLayout = layout;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    key: ValueKey('category_chip_$cat'),
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                    selectedColor: const Color(0xFFFF5252),
                    backgroundColor: const Color(0xFF1E1E24),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFFF5252) : Colors.white12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredFrames.length,
                itemBuilder: (context, index) {
                  final frame = filteredFrames[index];
                  return FrameCard(
                    frame: frame,
                    layout: _currentLayout,
                    onTap: () {
                      widget.onFrameSelected?.call(_currentLayout, frame);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
