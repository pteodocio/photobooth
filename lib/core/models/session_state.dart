import 'captured_photo.dart';
import 'frame_template.dart';
import 'layout_type.dart';
import 'photo_filter.dart';
import 'print_format.dart';

sealed class BoothSessionState {
  const BoothSessionState();
}

class SessionInitial extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate? frame;

  const SessionInitial({
    required this.layout,
    this.frame,
  });
}

class SessionCountingDown extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;
  final int currentShot; // 1 to burstCount
  final int secondsRemaining;
  final String posePrompt;

  const SessionCountingDown({
    required this.layout,
    required this.frame,
    required this.currentShot,
    required this.secondsRemaining,
    required this.posePrompt,
  });
}

class SessionCapturing extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;
  final int currentShot;
  final String posePrompt;

  const SessionCapturing({
    required this.layout,
    required this.frame,
    required this.currentShot,
    required this.posePrompt,
  });
}

class SessionContactSheet extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;
  final List<CapturedPhoto> allShots;
  final List<String> selectedShotIds; // exactly layout.slotCount elements in display order
  final PhotoFilter selectedFilter;
  final PrintFormat selectedPrintFormat;

  const SessionContactSheet({
    required this.layout,
    required this.frame,
    required this.allShots,
    required this.selectedShotIds,
    this.selectedFilter = PhotoFilter.none,
    this.selectedPrintFormat = PrintFormat.singleStrip,
  });

  SessionContactSheet copyWith({
    LayoutType? layout,
    FrameTemplate? frame,
    List<CapturedPhoto>? allShots,
    List<String>? selectedShotIds,
    PhotoFilter? selectedFilter,
    PrintFormat? selectedPrintFormat,
  }) {
    return SessionContactSheet(
      layout: layout ?? this.layout,
      frame: frame ?? this.frame,
      allShots: allShots ?? this.allShots,
      selectedShotIds: selectedShotIds ?? this.selectedShotIds,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedPrintFormat: selectedPrintFormat ?? this.selectedPrintFormat,
    );
  }
}

class SessionCompositing extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;

  const SessionCompositing({
    required this.layout,
    required this.frame,
  });
}

class SessionExportReady extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;
  final String compositeFilePath;

  const SessionExportReady({
    required this.layout,
    required this.frame,
    required this.compositeFilePath,
  });
}
