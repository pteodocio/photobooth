import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/photo_filter.dart';
import 'package:photobooth/core/models/print_format.dart';
import 'package:photobooth/core/models/composite_job.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';

void main() {
  test('PhotoFilter enum contains all specified presets with valid 20-element matrices', () {
    expect(PhotoFilter.values.length, 4);
    for (final filter in PhotoFilter.values) {
      expect(filter.matrix.length, 20, reason: '${filter.name} matrix must have 20 elements');
      expect(filter.displayName.isNotEmpty, isTrue);
    }
    expect(PhotoFilter.none.displayName, 'Original');
    expect(PhotoFilter.haruBlue.displayName, 'Haru Blue');
    expect(PhotoFilter.warmFilm.displayName, 'Warm Film');
    expect(PhotoFilter.mono.displayName, 'Film Noir');
  });

  test('PrintFormat enum defines dimensions and aspect ratios correctly', () {
    expect(PrintFormat.singleStrip.canvasWidth, 1200);
    expect(PrintFormat.singleStrip.canvasHeight, 3600);
    expect(PrintFormat.singleStrip.aspectRatio, closeTo(1 / 3, 0.001));

    expect(PrintFormat.twinStrip.canvasWidth, 2400);
    expect(PrintFormat.twinStrip.canvasHeight, 3600);
    expect(PrintFormat.twinStrip.aspectRatio, closeTo(2 / 3, 0.001));
  });

  test('CompositeJob defaults to PhotoFilter.none and PrintFormat.singleStrip', () {
    final job = CompositeJob(
      photoPaths: ['/tmp/p1.jpg'],
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: '/tmp/strip.png',
    );

    expect(job.filter, PhotoFilter.none);
    expect(job.printFormat, PrintFormat.singleStrip);
    expect(job.studioWatermark, contains('LIFE FOUR CUTS'));
    expect(job.qrData, isNotEmpty);
  });
}
