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
    aspectRatio: 2 / 3,
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
