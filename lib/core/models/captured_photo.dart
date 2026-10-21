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
