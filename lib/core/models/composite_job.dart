import 'frame_template.dart';
import 'layout_type.dart';

class CompositeJob {
  final List<String> photoPaths;
  final FrameTemplate frame;
  final LayoutType layout;
  final String dateString;
  final String outputPath;

  const CompositeJob({
    required this.photoPaths,
    required this.frame,
    required this.layout,
    required this.dateString,
    required this.outputPath,
  });
}
