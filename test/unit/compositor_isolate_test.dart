import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photobooth/core/models/composite_job.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/core/models/photo_filter.dart';
import 'package:photobooth/core/models/print_format.dart';
import 'package:photobooth/services/compositor_service_impl.dart';

void main() {
  late Directory testDir;
  late List<String> dummyPhotoPaths;
  late CompositorServiceImpl compositor;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('comp_test_');
    dummyPhotoPaths = [];
    for (int i = 0; i < 4; i++) {
      final image = img.Image(width: 800, height: 600);
      img.fill(image, color: img.ColorRgb8(i * 50, 100, 200));
      final file = File('${testDir.path}/test_$i.png');
      await file.writeAsBytes(img.encodePng(image));
      dummyPhotoPaths.add(file.path);
    }
    compositor = CompositorServiceImpl();
  });

  tearDown(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  test('renderStrip produces valid 1200x3600 PNG in isolate', () async {
    final outputPath = '${testDir.path}/output_strip.png';
    final job = CompositeJob(
      photoPaths: dummyPhotoPaths,
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: outputPath,
    );

    final resultPath = await compositor.renderStrip(job);
    expect(resultPath, equals(outputPath));

    final outputFile = File(resultPath);
    expect(await outputFile.exists(), isTrue);

    final decoded = img.decodePng(await outputFile.readAsBytes());
    expect(decoded, isNotNull);
    expect(decoded!.width, 1200);
    expect(decoded.height, 3600);
  });

  test('renderStrip handles large high-res photos without memory exhaustion', () async {
    final largePhotoPaths = <String>[];
    for (int i = 0; i < 4; i++) {
      final largeImage = img.Image(width: 3200, height: 2400);
      img.fill(largeImage, color: img.ColorRgb8(100, 150, 200));
      final file = File('${testDir.path}/large_$i.png');
      await file.writeAsBytes(img.encodePng(largeImage));
      largePhotoPaths.add(file.path);
    }

    final outputPath = '${testDir.path}/large_output_strip.png';
    final job = CompositeJob(
      photoPaths: largePhotoPaths,
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: outputPath,
    );

    final resultPath = await compositor.renderStrip(job);
    expect(File(resultPath).existsSync(), isTrue);
  });

  test('renderStrip applies PhotoFilter.mono producing grayscale output', () async {
    final outputPath = '${testDir.path}/mono_strip.png';
    final job = CompositeJob(
      photoPaths: dummyPhotoPaths,
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: outputPath,
      filter: PhotoFilter.mono,
    );

    final resultPath = await compositor.renderStrip(job);
    final outputFile = File(resultPath);
    expect(await outputFile.exists(), isTrue);

    final decoded = img.decodePng(await outputFile.readAsBytes())!;
    // Sample a pixel inside the first photo slot (e.g. x=200, y=200)
    final pixel = decoded.getPixel(200, 200);
    expect(pixel.r, equals(pixel.g));
    expect(pixel.g, equals(pixel.b));
  });

  test('renderStrip applies PhotoFilter.haruBlue and PhotoFilter.warmFilm correctly', () async {
    final grayPhoto = img.Image(width: 800, height: 600);
    img.fill(grayPhoto, color: img.ColorRgb8(100, 100, 100));
    final testFile = File('${testDir.path}/gray.png');
    await testFile.writeAsBytes(img.encodePng(grayPhoto));

    // Haru Blue test
    final haruPath = '${testDir.path}/haru_strip.png';
    await compositor.renderStrip(CompositeJob(
      photoPaths: [testFile.path, testFile.path, testFile.path, testFile.path],
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: haruPath,
      filter: PhotoFilter.haruBlue,
    ));
    final haruDecoded = img.decodePng(await File(haruPath).readAsBytes())!;
    final haruPixel = haruDecoded.getPixel(200, 200);
    expect(haruPixel.r, equals(110));
    expect(haruPixel.g, equals(117));
    expect(haruPixel.b, equals(140));

    // Warm Film test
    final warmPath = '${testDir.path}/warm_strip.png';
    await compositor.renderStrip(CompositeJob(
      photoPaths: [testFile.path, testFile.path, testFile.path, testFile.path],
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: warmPath,
      filter: PhotoFilter.warmFilm,
    ));
    final warmDecoded = img.decodePng(await File(warmPath).readAsBytes())!;
    final warmPixel = warmDecoded.getPixel(200, 200);
    expect(warmPixel.r, equals(132));
    expect(warmPixel.g, equals(118));
    expect(warmPixel.b, equals(78));
  });

  test('renderStrip renders QR code in bottom margin', () async {
    final outputPath = '${testDir.path}/qr_strip.png';
    final job = CompositeJob(
      photoPaths: dummyPhotoPaths,
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: outputPath,
      qrData: 'https://photobooth.app/strip?s=test1234',
    );

    final resultPath = await compositor.renderStrip(job);
    final decoded = img.decodePng(await File(resultPath).readAsBytes())!;

    // Check QR code bounding box (x: 980 to 1120, y: 3280 to 3420)
    // Find captionColor pixels inside QR code area
    final capArgb = job.frame.captionColorValue;
    final capR = (capArgb >> 16) & 0xFF;
    final capG = (capArgb >> 8) & 0xFF;
    final capB = capArgb & 0xFF;

    int darkModulePixels = 0;
    for (int y = 3280; y < 3420; y++) {
      for (int x = 980; x < 1120; x++) {
        final p = decoded.getPixel(x, y);
        if (p.r == capR && p.g == capG && p.b == capB) {
          darkModulePixels++;
        }
      }
    }
    expect(darkModulePixels, greaterThan(100), reason: 'QR code modules should be rendered in caption color');
  });

  test('renderStrip renders twinStrip (2400x3600) with center cut line', () async {
    final outputPath = '${testDir.path}/twin_strip.png';
    final job = CompositeJob(
      photoPaths: dummyPhotoPaths,
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: outputPath,
      printFormat: PrintFormat.twinStrip,
    );

    final resultPath = await compositor.renderStrip(job);
    final outputFile = File(resultPath);
    expect(await outputFile.exists(), isTrue);

    final decoded = img.decodePng(await outputFile.readAsBytes())!;
    expect(decoded.width, 2400);
    expect(decoded.height, 3600);
  });

  test('renderStrip renders centered studio watermark in bottom margin', () async {
    final outputPath = "${testDir.path}/wm_strip.png";
    final job = CompositeJob(
      photoPaths: dummyPhotoPaths,
      frame: FrameTemplate.bundledFrames.first,
      layout: LayoutType.fourCut,
      dateString: '2026.10.21',
      outputPath: outputPath,
      studioWatermark: 'LIFE FOUR CUTS - PHOTO STUDIO',
    );

    final resultPath = await compositor.renderStrip(job);
    final decoded = img.decodePng(await File(resultPath).readAsBytes())!;

    final capArgb = job.frame.captionColorValue;
    final capR = (capArgb >> 16) & 0xFF;
    final capG = (capArgb >> 8) & 0xFF;
    final capB = capArgb & 0xFF;

    // Scan across the centered watermark area around y = 3240
    int wmPixels = 0;
    for (int y = 3240; y < 3270; y++) {
      for (int x = 200; x < 1000; x++) {
        final p = decoded.getPixel(x, y);
        if (p.r == capR && p.g == capG && p.b == capB) {
          wmPixels++;
        }
      }
    }
    expect(wmPixels, greaterThan(50), reason: 'Centered studio watermark should be rendered in caption color');
  });
}
