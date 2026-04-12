import 'dart:math';

import '../../../core/models/puzzle_type.dart';

/// State for a single rotatable tile.
class RotateTile {
  RotateTile({
    required this.index,
    required this.col,
    required this.row,
    required this.currentAngle, // 0 | 90 | 180 | 270
  });

  final int index;
  final int col;
  final int row;
  int currentAngle;

  bool get isCorrect => currentAngle == 0;

  /// Rotate 90° clockwise.
  void rotateClockwise() {
    currentAngle = (currentAngle + 90) % 360;
  }
}

/// Generates and manages rotate-puzzle state.
class RotateEngine {
  RotateEngine({required this.difficulty})
      : grid = difficulty.rotateGrid;

  final Difficulty difficulty;
  final int grid;
  late List<RotateTile> _tiles;

  List<RotateTile> get tiles => List.unmodifiable(_tiles);

  void shuffle() {
    final rng = Random();
    final allowed = difficulty.rotateAllowedAngles;
    _tiles = List.generate(
      grid * grid,
      (i) {
        final col = i % grid;
        final row = i ~/ grid;
        // Pick a random non-zero angle from allowed list
        final nonZero =
            allowed.where((a) => a != 0).toList();
        final angle = nonZero.isEmpty
            ? 0
            : nonZero[rng.nextInt(nonZero.length)];
        return RotateTile(
            index: i, col: col, row: row, currentAngle: angle);
      },
    );
  }

  /// Rotate tile at [index] clockwise (clamped to allowed angles).
  void rotateTile(int index) {
    final tile = _tiles[index];
    final allowed = difficulty.rotateAllowedAngles;
    // Find next allowed angle after current
    final current = tile.currentAngle;
    final idx = allowed.indexOf(current);
    final next = allowed[(idx + 1) % allowed.length];
    tile.currentAngle = next;
  }

  bool get isSolved => _tiles.every((t) => t.isCorrect);

  int get correctCount => _tiles.where((t) => t.isCorrect).length;
}
