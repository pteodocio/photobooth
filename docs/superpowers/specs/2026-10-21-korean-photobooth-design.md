# Design Specification: Korean 4-Cut Photobooth (Milestone 1 — Core Flow MVP)

- **Date:** 2026-10-21
- **Status:** Draft for Review
- **Owner:** Project Owner
- **Scope:** Milestone 1 — End-to-End Core Flow (Frame Picker → Burst Capture → Contact Sheet Selection → Film Strip Compositing → Camera Roll & Share Export)

---

## 1. Overview & Context

This document specifies the technical design for **Milestone 1** of the personal Korean 4-Cut Photobooth (인생네컷) mobile application in Flutter (Dart).

Milestone 1 delivers a fully functional, offline-first MVP that allows the user to:
1. Select a frame layout (4-cut default, 6-cut, single photo) and visual frame style from bundled presets.
2. Experience a timed camera burst session (3s countdown with haptics and audio cues, rotating non-repeating pose prompts, screen flash, and automatic capture of $N+2$ shots).
3. Review thumbnails on a contact sheet, select exactly $N$ shots, and reorder them via drag-and-drop.
4. Render a high-resolution (1200 × 3600 px, 300 DPI) film-strip composite in a pure Dart background isolate with the frame overlay and `YYYY.MM.DD` date stamp.
5. Export the resulting strip to the device camera roll or OS share sheet.
6. Automatically clean up all raw capture files upon session finish, cancellation, or retake.

---

## 2. System Architecture & Directory Structure

```
photobooth/
├── lib/
│   ├── app.dart                                # MaterialApp, theme, routing
│   ├── main.dart                               # Entrypoint, dependency wiring
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_constants.dart              # Default timings, strip dimensions
│   │   │   └── pose_prompts.dart               # Pose guidance prompts catalog
│   │   ├── models/
│   │   │   ├── layout_type.dart                # Enum: fourCut, sixCut, single
│   │   │   ├── frame_template.dart             # Model: id, name, category, colors, overlay
│   │   │   ├── captured_photo.dart             # Model: id, filePath, timestamp, shotIndex
│   │   │   ├── composite_job.dart              # Model: input paths, frame, date, output path
│   │   │   └── session_state.dart              # Sealed class: session lifecycle states
│   │   └── services/
│   │       ├── camera_service.dart             # Abstract camera interface
│   │       ├── storage_service.dart            # Abstract temp file & session storage interface
│   │       ├── feedback_service.dart           # Abstract haptic, flash, and audio feedback
│   │       └── compositor_service.dart         # Abstract isolate compositing dispatcher
│   ├── features/
│   │   ├── frame_picker/
│   │   │   ├── controllers/frame_picker_controller.dart
│   │   │   ├── widgets/frame_card.dart
│   │   │   ├── widgets/layout_selector.dart
│   │   │   └── screens/frame_picker_screen.dart
│   │   ├── capture/
│   │   │   ├── controllers/capture_controller.dart
│   │   │   ├── widgets/countdown_overlay.dart
│   │   │   ├── widgets/flash_overlay.dart
│   │   │   ├── widgets/pose_prompt_card.dart
│   │   │   └── screens/capture_screen.dart
│   │   ├── contact_sheet/
│   │   │   ├── controllers/contact_sheet_controller.dart
│   │   │   ├── widgets/shot_thumbnail_tile.dart
│   │   │   └── screens/contact_sheet_screen.dart
│   │   ├── export/
│   │   │   ├── controllers/export_controller.dart
│   │   │   ├── widgets/strip_preview.dart
│   │   │   └── screens/export_screen.dart
│   │   └── session/
│   │       └── controllers/booth_session_controller.dart
│   └── services/
│       ├── camera_service_impl.dart            # Real camera package implementation
│       ├── mock_camera_service.dart            # Headless mock camera for tests
│       ├── storage_service_impl.dart           # Local directory management & cleanup
│       ├── feedback_service_impl.dart          # System haptics & audio players
│       └── compositor_service_impl.dart        # Background isolate image processing
└── test/
    ├── unit/
    │   ├── booth_session_controller_test.dart
    │   ├── pose_rotator_test.dart
    │   ├── storage_service_test.dart
    │   └── compositor_isolate_test.dart
    ├── widget/
    │   ├── frame_picker_screen_test.dart
    │   └── contact_sheet_screen_test.dart
    └── flows/
        └── full_photobooth_flow_test.dart
```

---

## 3. Data Models & State Contracts

### 3.1 `LayoutType`
```dart
enum LayoutType {
  fourCut(
    displayName: '4-Cut',
    slotCount: 4,
    burstCount: 6,
    aspectRatio: 4 / 3,
  ),
  sixCut(
    displayName: '6-Cut',
    slotCount: 6,
    burstCount: 8,
    aspectRatio: 4 / 3,
  ),
  single(
    displayName: 'Single',
    slotCount: 1,
    burstCount: 3,
    aspectRatio: 3 / 4,
  );

  const LayoutType({
    required this.displayName,
    required this.slotCount,
    required this.burstCount,
    required this.aspectRatio,
  });

  final String displayName;
  final int slotCount;
  final int burstCount;
  final double aspectRatio;
}
```

### 3.2 `FrameTemplate`
```dart
class FrameTemplate {
  final String id;
  final String name;
  final String category; // 'Classic Film', 'Colour Border'
  final int backgroundColorValue; // 32-bit ARGB hex
  final String? overlayAssetPath; // Optional PNG overlay asset
  final int captionColorValue;

  const FrameTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.backgroundColorValue,
    this.overlayAssetPath,
    required this.captionColorValue,
  });
}
```

**Bundled MVP Frames:**
1. `classic_black`: Hex `#FF121212`, white caption text `#FFFFFFFF`.
2. `vintage_white`: Hex `#FFF8F6F0`, charcoal caption text `#FF2B2B2B`.
3. `retro_cream`: Hex `#FFF4EBD9`, dark brown caption text `#FF3E2723`.
4. `pastel_pink`: Hex `#FFFCE4EC`, berry caption text `#FF880E4F`.
5. `deep_navy`: Hex `#FF0D1B2A`, white caption text `#FFFFFFFF`.
6. `muted_olive`: Hex `#FF283618`, cream caption text `#FFFEFAE0`.

### 3.3 `CapturedPhoto`
```dart
class CapturedPhoto {
  final String id;
  final String filePath;
  final DateTime timestamp;
  final int shotIndex;

  const CapturedPhoto({
    required this.id,
    required this.filePath,
    required this.timestamp,
    required this.shotIndex,
  });
}
```

### 3.4 `BoothSessionState`
```dart
sealed class BoothSessionState {
  const BoothSessionState();
}

class SessionInitial extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;
  const SessionInitial({required this.layout, required this.frame});
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
  const SessionContactSheet({
    required this.layout,
    required this.frame,
    required this.allShots,
    required this.selectedShotIds,
  });
}

class SessionCompositing extends BoothSessionState {
  final LayoutType layout;
  final FrameTemplate frame;
  const SessionCompositing({required this.layout, required this.frame});
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
```

---

## 4. Hardware & Infrastructure Services

### 4.1 `CameraService`
- **Interface**:
  - `Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back})`
  - `Widget buildPreview()`
  - `Future<void> switchCamera()`
  - `Future<String> takePicture(String destinationDirectory)`
  - `CameraLensDirection get currentDirection`
  - `bool get isInitialized`
  - `Future<void> dispose()`
- **Fallback**: If `CameraLensDirection.back` is unavailable on device, fall back to the first available camera index.
- **Orientation**: Locked using `controller.lockCaptureOrientation(DeviceOrientation.portraitUp)`.

### 4.2 `FeedbackService`
- **Countdown Tick**: `HapticFeedback.lightImpact()` per elapsed countdown second.
- **Final Countdown Tick (1s)**: `HapticFeedback.mediumImpact()` plus audio pitch alert.
- **Shutter Moment**: Screen flash (120ms white overlay at 70% opacity), `HapticFeedback.mediumImpact()`, mechanical shutter audio cue.

### 4.3 `StorageService`
- **Temp Storage Root**: `getApplicationSupportDirectory() / sessions / {sessionId}`.
- **Cleanup Triggers**:
  1. `cleanupOrphanedSessions()`: Runs on app startup, purges any leftover folders from prior runs.
  2. `clearSession(sessionId)`: Triggered on user "Cancel" or "Retake".
  3. `finalizeSession(sessionId)`: Deletes the raw burst directory once the composite PNG is saved.
- **Gallery Export**: Saves high-resolution PNG to the device public media store using platform channel (`gal` or `image_gallery_saver`).

---

## 5. Background Isolate Compositing Engine (`CompositorService`)

Compositing executes via `Isolate.run()` using pure Dart `package:image` with zero main-thread block.

### 5.1 Geometry Specification (4-Cut Strip)
- **Target Dimensions**: `1200 × 3600 px` (2:6 physical aspect ratio at 300 DPI).
- **Background**: Filled with `frame.backgroundColorValue`.
- **Photo Slots ($N=4$)**:
  - Width: `1040 px`, Height: `720 px` (Aspect ratio: ~1.44:1).
  - Horizontal margin: `80 px` on left and right (`(1200 - 1040) / 2`).
  - Top margin: `120 px`.
  - Inter-slot gutter: `40 px`.
  - Cumulative slot vertical offsets ($y$):
    - Slot 0: $y = 120$
    - Slot 1: $y = 120 + 720 + 40 = 880$
    - Slot 2: $y = 880 + 720 + 40 = 1640$
    - Slot 3: $y = 1640 + 720 + 40 = 2400$
    - Bottom margin / caption area: $3600 - (2400 + 720) = 480 px$.

### 5.2 Slot Cropping & Blitting
For each selected photo:
1. Decode input image file from disk.
2. Calculate source center-crop bounds matching `1040:720` aspect ratio.
3. Resize cropped region to exactly `1040 × 720 px` using bilinear interpolation.
4. Draw onto the canvas at `(80, slot.y)`.

### 5.3 Frame Overlay & Date Stamp
1. If `frame.overlayAssetPath` exists, decode PNG and blit across the full canvas with alpha blending.
2. Render date string in format `YYYY.MM.DD` (e.g. `2026.10.21`) centered horizontally in the bottom caption area at $y = 3300$ using `drawString` with the frame's `captionColorValue`.
3. Encode resulting `img.Image` to PNG bytes using `img.encodePng(image)`.
4. Write bytes to `compositeFilePath` and return path. Total execution time: $\le 1200\text{ ms}$.

---

## 6. Flow Controller & User Interaction

### 6.1 Session Controller (`BoothSessionController`)
- **`startSession(LayoutType layout, FrameTemplate frame)`**:
  - Initializes session ID and creates temp directory.
  - Transitions state to `SessionCountingDown(currentShot: 1, secondsRemaining: 3)`.
  - Starts 1-second countdown ticker with audio/haptic feedback.
- **`captureShot()`**:
  - Triggers screen flash + shutter sound + haptic.
  - Calls `cameraService.takePicture()`.
  - Stores shot in session list.
  - If `currentShot < burstCount`: picks next non-repeating pose prompt, waits 5s interval, restarts countdown.
  - If `currentShot == burstCount`: transitions state to `SessionContactSheet`.
- **`selectShot(String photoId)` / `reorderShots(int oldIndex, int newIndex)`**:
  - Toggles selection status; enforces max selection count of $N$.
  - Allows dragging items within `selectedShotIds` to reorder the final strip sequence.
- **`confirmSelection()`**:
  - Transitions state to `SessionCompositing`.
  - Launches `CompositorService.renderStrip(job)`.
  - On render completion, transitions to `SessionExportReady`.
- **`cancelSession()` / `retakeBurst()`**:
  - Deletes current session directory and files.
  - Retake restarts countdown at shot 1; Cancel returns to `FramePickerScreen`.

---

## 7. Error Handling & Edge Cases

| Scenario | Handling Strategy |
|---|---|
| Camera permission denied | Show informative permission request screen with direct link to system settings. |
| Device lacks rear camera | Automatically detect available lenses and select the first available lens (e.g. front camera). |
| Session abandoned / App crash | `StorageService.cleanupOrphanedSessions()` scans and deletes dangling temp folders on next launch. |
| Memory pressure on capture | Capture files written directly to disk path; downsampled decoding in isolate prevents out-of-memory errors. |
| User retakes after 6 shots | Previous 6 shots deleted from temp disk before new burst starts. |

---

## 8. Verification & Testing Plan

### 8.1 Unit Tests
- `booth_session_controller_test.dart`:
  - Verify complete lifecycle: initial → countdown → burst (6 shots for 4-cut) → contact sheet → compositing → export ready.
  - Verify selection count restriction: cannot proceed to compositing unless exactly $N$ photos are selected.
  - Verify retake deletes photos and resets shot index to 1.
  - Verify cancel deletes session files and returns to initial state.
- `pose_rotator_test.dart`:
  - Run 1000 iterations to ensure two identical pose prompts are never returned consecutively.
- `compositor_isolate_test.dart`:
  - Feed 4 dummy images into pure Dart isolate and assert generated PNG has dimensions `1200 × 3600 px` and contains valid PNG header bytes.
- `storage_service_test.dart`:
  - Assert orphaned directory purge deletes outdated directories while preserving active files.

### 8.2 Widget Tests
- `frame_picker_screen_test.dart`:
  - Test switching between 4-cut, 6-cut, and single layout tabs updates preview cards.
  - Test tapping a frame initiates session creation.
- `contact_sheet_screen_test.dart`:
  - Test tapping thumbnails toggles selection badges (1, 2, 3, 4).
  - Test "Bake Strip" button is disabled until 4 shots are selected.

### 8.3 End-to-End Simulation Test
- `full_photobooth_flow_test.dart`:
  - Uses `MockCameraService` to run through the entire experience without hardware dependencies.
