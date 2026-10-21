enum PhotoFilter {
  none(
    displayName: 'Original',
    matrix: [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
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
