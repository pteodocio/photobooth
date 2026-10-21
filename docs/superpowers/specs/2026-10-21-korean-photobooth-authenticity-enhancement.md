# Design Specification: Korean Photobooth Authenticity Enhancement (Milestone 2)

- **Date:** 2026-10-21
- **Status:** Draft for Review
- **Owner:** Project Owner
- **Scope:** Milestone 2 — Real Korean Photobooth Authenticity (Photo Tone Filters, Corner QR Code & Studio Watermark, Twin Strip "1+1" Print Mode)

---

## 1. Overview & Context

Following the completion of the Core Flow MVP (Milestone 1) and the Frame Theme expansion, this specification establishes the technical architecture for **Milestone 2**.

Milestone 2 integrates the three most recognizable physical and visual rituals of genuine Korean photo booth studios (*인생네컷 / Haru Film / Photoism*):
1. **Photo Tone Color Filters**: Instant post-capture film grading (Haru Cool Blue, Warm 90s Film, Film Noir B&W, and Natural Original).
2. **Authentic Corner QR Code & Studio Watermark**: Crisp procedural QR stamp encoding session verification and typographic studio branding (`인생네컷 • LIFE FOUR CUTS`).
3. **Twin Strip (1+1) Print Sheet**: Standard 4×6 inch (2400 × 3600 px, 300 DPI) side-by-side print layout with center scissor cut guidelines (`✂ - - - -`) designed for sharing with friends.

---

## 2. Architecture & Data Contracts

### 2.1 `PhotoFilter` Model
An enum defining the available color tone grading options, their display names, UI color transformation matrix, and isolate pixel adjustments.

```dart
// lib/core/models/photo_filter.dart

enum PhotoFilter {
  none(
    displayName: 'Original',
    matrix: [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
  ),
  haruBlue(
    displayName: 'Haru Blue',
    matrix: [
      0.95, 0.0,  0.05, 0.0, 10.0,
      0.0,  1.0,  0.05, 0.0, 12.0,
      0.0,  0.05, 1.15, 0.0, 20.0,
      0.0,  0.0,  0.0,  1.0, 0.0,
    ],
  ),
  warmFilm(
    displayName: 'Warm Film',
    matrix: [
      1.12, 0.05, 0.0,  0.0, 15.0,
      0.05, 1.05, 0.0,  0.0, 8.0,
      0.0,  0.0,  0.88, 0.0, -10.0,
      0.0,  0.0,  0.0,  1.0, 0.0,
    ],
  ),
  mono(
    displayName: 'Film Noir',
    matrix: [
      0.299, 0.587, 0.114, 0.0, 0.0,
      0.299, 0.587, 0.114, 0.0, 0.0,
      0.299, 0.587, 0.114, 0.0, 0.0,
      0.0,   0.0,   0.0,   1.0, 0.0,
    ],
  );

  final String displayName;
  final List<double> matrix;

  const PhotoFilter({
    required this.displayName,
    required this.matrix,
  });
}
```

### 2.2 `PrintFormat` Model
Defines the output layout: Single Strip vs. Twin Strip ("1+1").

```dart
// lib/core/models/print_format.dart

enum PrintFormat {
  singleStrip(
    displayName: 'Single Strip',
    canvasWidth: 1200,
    canvasHeight: 3600,
    aspectRatio: 1 / 3,
  ),
  twinStrip(
    displayName: 'Twin Strip (1+1)',
    canvasWidth: 2400,
    canvasHeight: 3600,
    aspectRatio: 2 / 3, // Standard 4x6" print ratio
  );

  final String displayName;
  final int canvasWidth;
  final int canvasHeight;
  final double aspectRatio;

  const PrintFormat({
    required this.displayName,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.aspectRatio,
  });
}
```

### 2.3 Extended `CompositeJob`
`CompositeJob` is extended to accept the chosen `PhotoFilter`, `PrintFormat`, and optional `studioWatermark`.

```dart
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
    this.studioWatermark = '인생네컷 • LIFE FOUR CUTS',
    this.qrData = 'https://photobooth.app/strip',
  });
}
```

### 2.4 State Transitions in `BoothSessionController`
* `SessionContactSheet` now carries:
  * `PhotoFilter selectedFilter` (defaults to `PhotoFilter.none`)
  * `PrintFormat selectedPrintFormat` (defaults to `PrintFormat.singleStrip`)
* Added controller methods:
  * `void setFilter(PhotoFilter filter)`: Updates state with newly selected filter; triggers immediate UI re-render.
  * `void setPrintFormat(PrintFormat format)`: Updates state with single vs twin preference.
* `confirmSelection()` passes both `selectedFilter` and `selectedPrintFormat` into `CompositeJob`.

---

## 3. Background Isolate Compositing Engine

Compositing runs completely off-thread in pure Dart via `Isolate.run()`.

### 3.1 Pixel-Level Color Grading (`_applyFilter`)
Photos are pre-downscaled for memory safety, cropped, and then processed with pure-Dart pixel color adjustments before placement:
* **`PhotoFilter.haruBlue`**:
  * Brightness +8%, slight cool-cyan lift in highlights ($B \times 1.15 + 15$, $R \times 0.95$).
* **`PhotoFilter.warmFilm`**:
  * Warm vintage tint ($R \times 1.12 + 10$, $G \times 1.05 + 5$, $B \times 0.90$).
* **`PhotoFilter.mono`**:
  * ITU-R BT.601 luma calculation: $Y = 0.299R + 0.587G + 0.114B$.
  * S-curve contrast stretch for authentic high-contrast film black & white.

### 3.2 Procedural Corner QR Code (`_drawQrCode`)
* Uses `package:qr` to generate a 21×21 QR matrix (`QrCode.fromData(data: job.qrData, errorCorrectLevel: QrErrorCorrectLevel.M)`).
* Scaled up to a 140×140 px square placed in the bottom margin opposite the date stamp (bottom-right: $X = 980$, $Y = 3280$).
* Drawn with high contrast against the frame background: module pixels match the frame's `captionColorValue`, with a subtle 4px quiet zone border.

### 3.3 Studio Watermark Inscription (`_drawWatermark`)
* Bottom margin typography centered at $Y = 3250$:
  `인생네컷 • LIFE FOUR CUTS`
* Drawn above the date stamp in the frame's `captionColorValue`.

### 3.4 Twin Strip (1+1) Dual-Canvas Assembly
When `job.printFormat == PrintFormat.twinStrip`:
1. Canvas dimensions expand to **2400 × 3600 px** (matching 4×6 inch print postcards).
2. The complete single strip (photos, border, date stamp, QR code, and watermark) is rendered onto a 1200 × 3600 memory image.
3. The image is drawn twice side-by-side:
   * Left Strip: $(0, 0)$ to $(1200, 3600)$
   * Right Strip: $(1200, 0)$ to $(2400, 3600)$
4. Center cut guide: A vertical dashed line with subtle scissor markers (`✂`) is rendered down $X = 1200$.

---

## 4. UI / UX Design Specifications

### 4.1 Contact Sheet Screen (`ContactSheetScreen`)
* **Live Filter Picker Bar**:
  * Located beneath the thumbnail grid and reorder tray.
  * 4 selectable filter pills (`Original`, `Haru Blue`, `Warm Film`, `Film Noir`).
  * Instant real-time preview on all thumbnails via `ColorFiltered(colorFilter: ColorFilter.matrix(filter.matrix))`.
* **Print Format Selector**:
  * Segmented button / pill toggle: `Single Strip` vs. `Twin 1+1 (Share with Friend)`.
* **"Bake Film Strip" Action**:
  * Maintains existing strict selection validation (disabled until exactly $N$ photos are selected).

### 4.2 Export Screen (`ExportScreen`)
* **Responsive Strip Preview**:
  * Automatically adjusts aspect ratio preview: 1:3 for Single Strip, 2:3 for Twin Strip.
* **Instant Re-Bake / Format Toggle**:
  * Switch between Single and Twin strip directly from the preview bar without leaving the screen.

---

## 5. Non-Functional Constraints & Memory Management

1. **Memory Budget**:
   * Pre-downscaling to $2\times$ slot dimensions prevents heap exhaustion during dual-strip 2400×3600 rendering.
2. **Zero Storage Leak**:
   * All intermediate isolate files are created within the active session folder and purged during `finalizeSession` or `cancelSession`.
3. **Offline & Privacy First**:
   * QR generation and image processing are 100% local with no network dependencies.

---

## 6. Verification & Test Plan

1. **Unit Tests**:
   * `test/unit/photo_filter_test.dart`: Verifies matrix definitions and filter application logic.
   * `test/unit/compositor_isolate_test.dart`:
     * Verify single strip (1200×3600) compositing with filter and QR code.
     * Verify twin strip (2400×3600) dual-canvas compositing with center guide.
2. **Widget Tests**:
   * `test/widget/contact_sheet_screen_test.dart`:
     * Verify filter bar rendering and selection state.
     * Verify print format toggle and selection state.
3. **End-to-End Flow Test**:
   * `test/flows/full_photobooth_flow_test.dart`:
     * End-to-end journey from frame picker -> burst capture -> filter selection -> twin strip baking -> export.
