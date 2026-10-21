import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/captured_photo.dart';
import 'package:photobooth/core/models/composite_job.dart';
import 'package:photobooth/core/models/session_state.dart';
import 'package:photobooth/core/models/photo_filter.dart';
import 'package:photobooth/core/models/print_format.dart';

void main() {
  test('LayoutType parameters match specification', () {
    expect(LayoutType.fourCut.slotCount, 4);
    expect(LayoutType.fourCut.burstCount, 6);
    expect(LayoutType.fourCut.aspectRatio, closeTo(4 / 3, 0.01));

    expect(LayoutType.sixCut.slotCount, 6);
    expect(LayoutType.sixCut.burstCount, 8);
    expect(LayoutType.sixCut.aspectRatio, closeTo(4 / 3, 0.01));

    expect(LayoutType.single.slotCount, 1);
    expect(LayoutType.single.burstCount, 3);
    expect(LayoutType.single.aspectRatio, closeTo(3 / 4, 0.01));
  });

  test('Bundled frame templates include at least 16 styles with unique IDs', () {
    expect(FrameTemplate.bundledFrames.length, greaterThanOrEqualTo(16));
    final ids = FrameTemplate.bundledFrames.map((f) => f.id).toList();
    final uniqueIds = ids.toSet();
    expect(uniqueIds.length, equals(ids.length), reason: 'Every frame ID must be unique');

    // Verify key classic and new aesthetic styles exist
    expect(uniqueIds.contains('classic_black'), isTrue);
    expect(uniqueIds.contains('vintage_white'), isTrue);
    expect(uniqueIds.contains('haru_sky_blue'), isTrue);
    expect(uniqueIds.contains('lavender_haze'), isTrue);
    expect(uniqueIds.contains('butter_yellow'), isTrue);
    expect(uniqueIds.contains('matcha_mint'), isTrue);
    expect(uniqueIds.contains('peach_blossom'), isTrue);
    expect(uniqueIds.contains('bubblegum_pop'), isTrue);
    expect(uniqueIds.contains('midnight_violet'), isTrue);
  });

  test('CapturedPhoto and CompositeJob properties', () {
    final photo = CapturedPhoto(
      id: 'p1',
      filePath: '/tmp/p1.jpg',
      timestamp: DateTime(2026, 10, 21),
      shotIndex: 1,
    );
    expect(photo.id, 'p1');
    expect(photo.shotIndex, 1);

    final job = CompositeJob(
      photoPaths: ['/tmp/p1.jpg'],
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: '/tmp/output.png',
    );
    expect(job.photoPaths.length, 1);
    expect(job.dateString, '2026.10.21');
    expect(job.filter, PhotoFilter.none);
    expect(job.printFormat, PrintFormat.singleStrip);
    expect(job.studioWatermark, 'LIFE FOUR CUTS - PHOTO STUDIO');
    expect(job.qrData, 'https://photobooth.app/strip');
  });

  test('BoothSessionState instances instantiate properly', () {
    final frame = FrameTemplate.bundledFrames.first;
    const initial = SessionInitial(layout: LayoutType.fourCut, frame: null);
    expect(initial.layout, LayoutType.fourCut);
    expect(initial.frame, isNull);

    final countingDown = SessionCountingDown(
      layout: LayoutType.fourCut,
      frame: frame,
      currentShot: 1,
      secondsRemaining: 3,
      posePrompt: 'Finger heart 🫰',
    );
    expect(countingDown.currentShot, 1);
    expect(countingDown.secondsRemaining, 3);
    expect(countingDown.posePrompt, 'Finger heart 🫰');

    final photo = CapturedPhoto(
      id: 'p1',
      filePath: '/tmp/p1.jpg',
      timestamp: DateTime(2026, 10, 21),
      shotIndex: 1,
    );
    final contactSheet = SessionContactSheet(
      layout: LayoutType.fourCut,
      frame: frame,
      allShots: [photo],
      selectedShotIds: ['p1'],
    );
    expect(contactSheet.selectedFilter, PhotoFilter.none);
    expect(contactSheet.selectedPrintFormat, PrintFormat.singleStrip);

    final updatedSheet = contactSheet.copyWith(
      selectedFilter: PhotoFilter.haruBlue,
      selectedPrintFormat: PrintFormat.twinStrip,
    );
    expect(updatedSheet.selectedFilter, PhotoFilter.haruBlue);
    expect(updatedSheet.selectedPrintFormat, PrintFormat.twinStrip);
  });
}
