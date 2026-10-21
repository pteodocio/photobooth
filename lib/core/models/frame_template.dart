class FrameTemplate {
  final String id;
  final String name;
  final String category;
  final int backgroundColorValue; // 32-bit ARGB
  final String? overlayAssetPath;
  final int captionColorValue;

  const FrameTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.backgroundColorValue,
    this.overlayAssetPath,
    required this.captionColorValue,
  });

  static const List<FrameTemplate> bundledFrames = [
    FrameTemplate(
      id: 'classic_black',
      name: 'Classic Black',
      category: 'Classic Film',
      backgroundColorValue: 0xFF121212,
      captionColorValue: 0xFFFFFFFF,
    ),
    FrameTemplate(
      id: 'vintage_white',
      name: 'Vintage White',
      category: 'Classic Film',
      backgroundColorValue: 0xFFF8F6F0,
      captionColorValue: 0xFF2B2B2B,
    ),
    FrameTemplate(
      id: 'retro_cream',
      name: 'Retro Cream',
      category: 'Colour Border',
      backgroundColorValue: 0xFFF4EBD9,
      captionColorValue: 0xFF3E2723,
    ),
    FrameTemplate(
      id: 'pastel_pink',
      name: 'Pastel Pink',
      category: 'Colour Border',
      backgroundColorValue: 0xFFFCE4EC,
      captionColorValue: 0xFF880E4F,
    ),
    FrameTemplate(
      id: 'deep_navy',
      name: 'Deep Navy',
      category: 'Colour Border',
      backgroundColorValue: 0xFF0D1B2A,
      captionColorValue: 0xFFFFFFFF,
    ),
    FrameTemplate(
      id: 'muted_olive',
      name: 'Muted Olive',
      category: 'Colour Border',
      backgroundColorValue: 0xFF283618,
      captionColorValue: 0xFFFEFAE0,
    ),
  ];
}
