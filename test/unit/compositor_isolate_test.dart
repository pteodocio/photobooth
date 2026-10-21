import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photobooth/core/models/composite_job.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
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
}
