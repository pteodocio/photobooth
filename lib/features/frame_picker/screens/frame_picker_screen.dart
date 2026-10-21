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

  @override
  void initState() {
    super.initState();
    _currentLayout = widget.initialLayout;
  }

  @override
  Widget build(BuildContext context) {
    final frames = FrameTemplate.bundledFrames;

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
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: frames.length,
                itemBuilder: (context, index) {
                  final frame = frames[index];
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
