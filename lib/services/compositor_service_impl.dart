import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import '../core/config/app_constants.dart';
import '../core/models/composite_job.dart';
import '../core/models/layout_type.dart';
import '../core/services/compositor_service.dart';

class CompositorServiceImpl implements CompositorService {
  @override
  Future<String> renderStrip(CompositeJob job) async {
    return await Isolate.run(() => _renderStripInternal(job));
  }

  static String _renderStripInternal(CompositeJob job) {
    const canvasWidth = AppConstants.stripWidth;
    const canvasHeight = AppConstants.stripHeight;

    // Background color parsing
    final bgArgb = job.frame.backgroundColorValue;
    final bgA = (bgArgb >> 24) & 0xFF;
    final bgR = (bgArgb >> 16) & 0xFF;
    final bgG = (bgArgb >> 8) & 0xFF;
    final bgB = bgArgb & 0xFF;

    final strip = img.Image(width: canvasWidth, height: canvasHeight);
    img.fill(strip, color: img.ColorRgba8(bgR, bgG, bgB, bgA));

    final slotCount = job.layout.slotCount;
    final photoPaths = job.photoPaths;

    // Slot layout calculations
    if (job.layout == LayoutType.fourCut) {
      const slotW = AppConstants.fourCutSlotWidth; // 1040
      const slotH = AppConstants.fourCutSlotHeight; // 720
      const marginX = AppConstants.fourCutMarginX; // 80
      const marginTop = AppConstants.fourCutMarginTop; // 120
      const gutter = AppConstants.fourCutGutter; // 40

      for (int i = 0; i < slotCount && i < photoPaths.length; i++) {
        final photoFile = File(photoPaths[i]);
        if (!photoFile.existsSync()) continue;

        final bytes = photoFile.readAsBytesSync();
        final rawPhoto = img.decodeImage(bytes);
        if (rawPhoto == null) continue;

        final slotY = marginTop + i * (slotH + gutter);
        _drawCroppedPhoto(strip, rawPhoto, marginX, slotY, slotW, slotH);
      }
    } else if (job.layout == LayoutType.sixCut) {
      // 2 columns x 3 rows
      const cols = 2;
      const slotW = 500;
      const slotH = 680;
      const marginX = 80;
      const marginTop = 120;
      const gutterX = 40;
      const gutterY = 40;

      for (int i = 0; i < slotCount && i < photoPaths.length; i++) {
        final photoFile = File(photoPaths[i]);
        if (!photoFile.existsSync()) continue;

        final rawPhoto = img.decodeImage(photoFile.readAsBytesSync());
        if (rawPhoto == null) continue;

        final col = i % cols;
        final row = i ~/ cols;
        final slotX = marginX + col * (slotW + gutterX);
        final slotY = marginTop + row * (slotH + gutterY);

        _drawCroppedPhoto(strip, rawPhoto, slotX, slotY, slotW, slotH);
      }
    } else {
      // Single hero photo
      const slotW = 1040;
      const slotH = 1400;
      const slotX = 80;
      const slotY = 120;

      if (photoPaths.isNotEmpty && File(photoPaths.first).existsSync()) {
        final rawPhoto = img.decodeImage(File(photoPaths.first).readAsBytesSync());
        if (rawPhoto != null) {
          _drawCroppedPhoto(strip, rawPhoto, slotX, slotY, slotW, slotH);
        }
      }
    }

    // Draw date stamp in bottom margin
    final capArgb = job.frame.captionColorValue;
    final capA = (capArgb >> 24) & 0xFF;
    final capR = (capArgb >> 16) & 0xFF;
    final capG = (capArgb >> 8) & 0xFF;
    final capB = capArgb & 0xFF;
    final fontColor = img.ColorRgba8(capR, capG, capB, capA);

    // Date stamp centered around y = 3300
    img.drawString(
      strip,
      job.dateString,
      font: img.arial48,
      x: (canvasWidth - (job.dateString.length * 28)) ~/ 2,
      y: 3320,
      color: fontColor,
    );

    // Save PNG
    final pngBytes = img.encodePng(strip);
    final outFile = File(job.outputPath);
    if (!outFile.parent.existsSync()) {
      outFile.parent.createSync(recursive: true);
    }
    outFile.writeAsBytesSync(pngBytes);

    return job.outputPath;
  }

  static void _drawCroppedPhoto(
    img.Image canvas,
    img.Image source,
    int destX,
    int destY,
    int targetW,
    int targetH,
  ) {
    final targetAspect = targetW / targetH;
    final srcAspect = source.width / source.height;

    int cropX = 0;
    int cropY = 0;
    int cropW = source.width;
    int cropH = source.height;

    if (srcAspect > targetAspect) {
      cropW = (source.height * targetAspect).round();
      cropX = ((source.width - cropW) / 2).round();
    } else {
      cropH = (source.width / targetAspect).round();
      cropY = ((source.height - cropH) / 2).round();
    }

    final cropped = img.copyCrop(
      source,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final resized = img.copyResize(
      cropped,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.linear,
    );

    img.compositeImage(canvas, resized, dstX: destX, dstY: destY);
  }
}
