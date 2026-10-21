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
    // 1. Classic Film
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
      id: 'slate_minimal',
      name: 'Slate Minimal',
      category: 'Classic Film',
      backgroundColorValue: 0xFF334155,
      captionColorValue: 0xFFF8FAFC,
    ),
    FrameTemplate(
      id: 'charcoal_noir',
      name: 'Charcoal Noir',
      category: 'Classic Film',
      backgroundColorValue: 0xFF1E2022,
      captionColorValue: 0xFFD1D5DB,
    ),

    // 2. Pastel Aesthetic (Haru Film / K-Photobooth vibes)
    FrameTemplate(
      id: 'haru_sky_blue',
      name: 'Haru Sky Blue',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFCBE1FC,
      captionColorValue: 0xFF1E3A8A,
    ),
    FrameTemplate(
      id: 'pastel_pink',
      name: 'Pastel Pink',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFFCE4EC,
      captionColorValue: 0xFF880E4F,
    ),
    FrameTemplate(
      id: 'lavender_haze',
      name: 'Lavender Haze',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFE8DEF8,
      captionColorValue: 0xFF4A148C,
    ),
    FrameTemplate(
      id: 'butter_yellow',
      name: 'Butter Yellow',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFFEF3C7,
      captionColorValue: 0xFF78350F,
    ),
    FrameTemplate(
      id: 'matcha_mint',
      name: 'Matcha Mint',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFD8E8D5,
      captionColorValue: 0xFF1B4332,
    ),
    FrameTemplate(
      id: 'peach_blossom',
      name: 'Peach Blossom',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFFFE4D6,
      captionColorValue: 0xFF9C4132,
    ),
    FrameTemplate(
      id: 'cloud_lilac',
      name: 'Cloud Lilac',
      category: 'Pastel Aesthetic',
      backgroundColorValue: 0xFFF3E8FF,
      captionColorValue: 0xFF581C87,
    ),

    // 3. Vintage & Earth
    FrameTemplate(
      id: 'retro_cream',
      name: 'Retro Cream',
      category: 'Vintage & Earth',
      backgroundColorValue: 0xFFF4EBD9,
      captionColorValue: 0xFF3E2723,
    ),
    FrameTemplate(
      id: 'muted_olive',
      name: 'Muted Olive',
      category: 'Vintage & Earth',
      backgroundColorValue: 0xFF283618,
      captionColorValue: 0xFFFEFAE0,
    ),
    FrameTemplate(
      id: 'warm_terracotta',
      name: 'Warm Terracotta',
      category: 'Vintage & Earth',
      backgroundColorValue: 0xFFD97757,
      captionColorValue: 0xFFFFF7ED,
    ),
    FrameTemplate(
      id: 'mocha_espresso',
      name: 'Mocha Espresso',
      category: 'Vintage & Earth',
      backgroundColorValue: 0xFF2D241E,
      captionColorValue: 0xFFF5EBE0,
    ),

    // 4. Vibrant & Pop
    FrameTemplate(
      id: 'bubblegum_pop',
      name: 'Bubblegum Pop',
      category: 'Vibrant & Pop',
      backgroundColorValue: 0xFFFF85A1,
      captionColorValue: 0xFFFFFFFF,
    ),
    FrameTemplate(
      id: 'cherry_red',
      name: 'Cherry Red',
      category: 'Vibrant & Pop',
      backgroundColorValue: 0xFF800E13,
      captionColorValue: 0xFFFFE3E0,
    ),
    FrameTemplate(
      id: 'electric_teal',
      name: 'Electric Teal',
      category: 'Vibrant & Pop',
      backgroundColorValue: 0xFF0F4C5C,
      captionColorValue: 0xFFE0FBFC,
    ),

    // 5. Cyber & Moody
    FrameTemplate(
      id: 'deep_navy',
      name: 'Deep Navy',
      category: 'Cyber & Moody',
      backgroundColorValue: 0xFF0D1B2A,
      captionColorValue: 0xFFFFFFFF,
    ),
    FrameTemplate(
      id: 'midnight_violet',
      name: 'Midnight Violet',
      category: 'Cyber & Moody',
      backgroundColorValue: 0xFF1E1B4B,
      captionColorValue: 0xFFC084FC,
    ),
  ];
}
