import 'dart:math';

/// State for a single rotatable tile.
class RotateTile {
  RotateTile({
    required this.index,
    required this.currentAngle, // 0 | 90 | 180 | 270
  });

  final int index;
  int currentAngle;

  bool get isCorrect => currentAngle == 0;
}

/// Generates and manages rotate-puzzle state.
class RotateEngine {
  RotateEngine({
    required this.tileCount,
    required this.allowedAngles,
  });

  final int tileCount;
  final List<int> allowedAngles;
  late List<RotateTile> _tiles;

  List<RotateTile> get tiles => List.unmodifiable(_tiles);

  void shuffle() {
    final rng = Random();
    final nonZero = allowedAngles.where((a) => a != 0).toList();
    _tiles = List.generate(
      tileCount,
      (i) {
        final angle =
            nonZero.isEmpty ? 0 : nonZero[rng.nextInt(nonZero.length)];
        return RotateTile(index: i, currentAngle: angle);
      },
    );
  }

  /// Rotate tile at [index] clockwise (clamped to allowed angles).
  void rotateTile(int index) {
    final tile = _tiles[index];
    final current = tile.currentAngle;
    final idx = allowedAngles.indexOf(current);
    final next = allowedAngles[(idx + 1) % allowedAngles.length];
    tile.currentAngle = next;
  }

  bool get isSolved => _tiles.every((t) => t.isCorrect);

  int get correctCount => _tiles.where((t) => t.isCorrect).length;
}
