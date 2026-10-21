import 'frame_template.dart';
import 'layout_type.dart';
import 'photo_filter.dart';
import 'print_format.dart';

class CompositeJob {
  final List<String> photoPaths;
  final FrameTemplate frame;
  final LayoutType layout;
  final String dateString;
  final String outputPath;
  final PhotoFilter filter;
  final PrintFormat printFormat;
  final String studioWatermark;
  final String qrData;

  const CompositeJob({
    required this.photoPaths,
    required this.frame,
    required this.layout,
    required this.dateString,
    required this.outputPath,
    this.filter = PhotoFilter.none,
    this.printFormat = PrintFormat.singleStrip,
    this.studioWatermark = 'LIFE FOUR CUTS - PHOTO STUDIO',
    this.qrData = 'https://photobooth.app/strip',
  });
}
