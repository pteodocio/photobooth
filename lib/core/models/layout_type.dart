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
