import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';
import '../core/config/app_constants.dart';
import '../core/models/composite_job.dart';
import '../core/models/layout_type.dart';
import '../core/models/photo_filter.dart';
import '../core/models/print_format.dart';
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
    final bgColor = img.ColorRgba8(bgR, bgG, bgB, bgA);

    final strip = img.Image(width: canvasWidth, height: canvasHeight);
    img.fill(strip, color: bgColor);

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

        var rawPhoto = img.decodeImage(photoFile.readAsBytesSync());
        if (rawPhoto == null) continue;
        rawPhoto = img.bakeOrientation(rawPhoto);

        final slotY = marginTop + i * (slotH + gutter);
        _drawCroppedPhoto(strip, rawPhoto, marginX, slotY, slotW, slotH, job.filter);
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

        var rawPhoto = img.decodeImage(photoFile.readAsBytesSync());
        if (rawPhoto == null) continue;
        rawPhoto = img.bakeOrientation(rawPhoto);

        final col = i % cols;
        final row = i ~/ cols;
        final slotX = marginX + col * (slotW + gutterX);
        final slotY = marginTop + row * (slotH + gutterY);

        _drawCroppedPhoto(strip, rawPhoto, slotX, slotY, slotW, slotH, job.filter);
      }
    } else {
      // Single hero photo
      const slotW = 1040;
      const slotH = 1400;
      const slotX = 80;
      const slotY = 120;

      if (photoPaths.isNotEmpty && File(photoPaths.first).existsSync()) {
        var rawPhoto = img.decodeImage(File(photoPaths.first).readAsBytesSync());
        if (rawPhoto != null) {
          rawPhoto = img.bakeOrientation(rawPhoto);
          _drawCroppedPhoto(strip, rawPhoto, slotX, slotY, slotW, slotH, job.filter);
        }
      }
    }

    // Caption color parsing
    final capArgb = job.frame.captionColorValue;
    final capA = (capArgb >> 24) & 0xFF;
    final capR = (capArgb >> 16) & 0xFF;
    final capG = (capArgb >> 8) & 0xFF;
    final capB = capArgb & 0xFF;
    final fontColor = img.ColorRgba8(capR, capG, capB, capA);

    // Draw watermark & date
    _drawWatermark(strip, job, fontColor);

    // Draw QR code in bottom margin (e.g. x = 980, y = 3280, 140x140)
    _drawQrCode(
      strip,
      job.qrData,
      startX: 980,
      startY: 3280,
      targetSize: 140,
      fgColor: fontColor,
      bgColor: bgColor,
    );

    img.Image outputImage = strip;

    // Twin Strip (1+1) Dual-Canvas Assembly
    if (job.printFormat == PrintFormat.twinStrip) {
      final twinImage = img.Image(width: 2400, height: 3600);
      img.fill(twinImage, color: bgColor);

      // Draw left strip at (0, 0)
      img.compositeImage(twinImage, strip, dstX: 0, dstY: 0);

      // Draw right strip at (1200, 0)
      img.compositeImage(twinImage, strip, dstX: 1200, dstY: 0);

      // Draw vertical dashed cut guideline down x = 1200
      const dashLength = 20;
      const dashGap = 15;
      for (int y = 0; y < 3600; y += dashLength + dashGap) {
        final yEnd = (y + dashLength).clamp(0, 3600);
        img.drawLine(
          twinImage,
          x1: 1200,
          y1: y,
          x2: 1200,
          y2: yEnd,
          color: fontColor,
          thickness: 2,
        );
      }

      // Draw scissor / cut marker at top (y=40) and bottom (y=3500)
      const markerText = '| - - |';
      img.drawString(
        twinImage,
        markerText,
        font: img.arial24,
        x: 1200 - 30,
        y: 40,
        color: fontColor,
      );
      img.drawString(
        twinImage,
        markerText,
        font: img.arial24,
        x: 1200 - 30,
        y: 3500,
        color: fontColor,
      );

      outputImage = twinImage;
    }

    // Save PNG
    final pngBytes = img.encodePng(outputImage);
    final outFile = File(job.outputPath);
    if (!outFile.parent.existsSync()) {
      outFile.parent.createSync(recursive: true);
    }
    outFile.writeAsBytesSync(pngBytes);

    return job.outputPath;
  }

  static img.Image _applyFilter(img.Image photo, PhotoFilter filter) {
    if (filter == PhotoFilter.none) return photo;

    for (final pixel in photo) {
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      switch (filter) {
        case PhotoFilter.none:
          break;
        case PhotoFilter.mono:
          final y = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
          pixel.r = y;
          pixel.g = y;
          pixel.b = y;
          break;
        case PhotoFilter.haruBlue:
          pixel.r = (0.95 * r + 0.05 * b + 10).round().clamp(0, 255);
          pixel.g = (1.00 * g + 0.05 * b + 12).round().clamp(0, 255);
          pixel.b = (0.05 * g + 1.15 * b + 20).round().clamp(0, 255);
          break;
        case PhotoFilter.warmFilm:
          pixel.r = (1.12 * r + 0.05 * g + 15).round().clamp(0, 255);
          pixel.g = (0.05 * r + 1.05 * g + 8).round().clamp(0, 255);
          pixel.b = (0.88 * b - 10).round().clamp(0, 255);
          break;
      }
    }
    return photo;
  }

  static void _drawWatermark(
    img.Image canvas,
    CompositeJob job,
    img.Color captionColor,
  ) {
    // Studio watermark centered around y = 3240
    if (job.studioWatermark.isNotEmpty) {
      final wmX = (canvas.width - (job.studioWatermark.length * 14)) ~/ 2;
      img.drawString(
        canvas,
        job.studioWatermark,
        font: img.arial24,
        x: wmX > 0 ? wmX : 10,
        y: 3240,
        color: captionColor,
      );
    }

    // Date string centered around y = 3320
    if (job.dateString.isNotEmpty) {
      img.drawString(
        canvas,
        job.dateString,
        font: img.arial48,
        x: (canvas.width - (job.dateString.length * 28)) ~/ 2,
        y: 3320,
        color: captionColor,
      );
    }
  }

  static void _drawQrCode(
    img.Image canvas,
    String data, {
    int startX = 980,
    int startY = 3280,
    int targetSize = 140,
    required img.Color fgColor,
    required img.Color bgColor,
  }) {
    if (data.isEmpty) return;
    try {
      final qrCode = QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.medium,
      );
      final qrImage = QrImage(qrCode);
      final moduleCount = qrImage.moduleCount;
      final modulePixelSize = (targetSize / (moduleCount + 2)).floor();
      final offset = (targetSize - (modulePixelSize * (moduleCount + 2))) ~/ 2;

      // Quiet zone background
      img.fillRect(
        canvas,
        x1: startX + offset,
        y1: startY + offset,
        x2: startX + offset + (moduleCount + 2) * modulePixelSize - 1,
        y2: startY + offset + (moduleCount + 2) * modulePixelSize - 1,
        color: bgColor,
      );

      // Dark modules
      for (int r = 0; r < moduleCount; r++) {
        for (int c = 0; c < moduleCount; c++) {
          if (qrImage.isDark(r, c)) {
            img.fillRect(
              canvas,
              x1: startX + offset + (c + 1) * modulePixelSize,
              y1: startY + offset + (r + 1) * modulePixelSize,
              x2: startX + offset + (c + 2) * modulePixelSize - 1,
              y2: startY + offset + (r + 2) * modulePixelSize - 1,
              color: fgColor,
            );
          }
        }
      }
    } catch (_) {
      // In case of invalid QR data, fail gracefully without failing the entire composite
    }
  }

  static void _drawCroppedPhoto(
    img.Image canvas,
    img.Image source,
    int destX,
    int destY,
    int targetW,
    int targetH,
    PhotoFilter filter,
  ) {
    img.Image working = source;

    // Memory optimization: if source photo is significantly larger than target slot,
    // pre-downscale to 2x target size to prevent massive heap consumption during crop.
    final maxAllowedW = targetW * 2;
    final maxAllowedH = targetH * 2;
    if (working.width > maxAllowedW && working.height > maxAllowedH) {
      final srcAspect = working.width / working.height;
      final targetAspect = targetW / targetH;
      if (srcAspect > targetAspect) {
        working = img.copyResize(working, height: maxAllowedH, interpolation: img.Interpolation.linear);
      } else {
        working = img.copyResize(working, width: maxAllowedW, interpolation: img.Interpolation.linear);
      }
    }

    final targetAspect = targetW / targetH;
    final srcAspect = working.width / working.height;

    int cropX = 0;
    int cropY = 0;
    int cropW = working.width;
    int cropH = working.height;

    if (srcAspect > targetAspect) {
      cropW = (working.height * targetAspect).round();
      cropX = ((working.width - cropW) / 2).round();
    } else {
      cropH = (working.width / targetAspect).round();
      cropY = ((working.height - cropH) / 2).round();
    }

    final cropped = img.copyCrop(
      working,
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

    final filtered = _applyFilter(resized, filter);

    img.compositeImage(canvas, filtered, dstX: destX, dstY: destY);
  }
}
