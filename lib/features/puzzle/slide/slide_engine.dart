import 'dart:math';

import '../../../core/models/puzzle_type.dart';

/// Slide-puzzle engine: generates solvable shuffled boards
/// and validates moves.
///
/// The empty tile is represented by index 0; numbered tiles 1..N.
class SlideEngine {
  SlideEngine({required this.difficulty})
      : grid = difficulty.slideGrid,
        tileCount = difficulty.slideTileCount;

  final Difficulty difficulty;
  final int grid;
  final int tileCount;

  late List<int> _tiles; // length = grid*grid; 0 = empty
  int _emptyIndex = 0;
  int _moveCount = 0;

  List<int> get tiles => List.unmodifiable(_tiles);
  int get moveCount => _moveCount;
  int get emptyIndex => _emptyIndex;

  /// Returns a freshly shuffled, solvable board.
  void shuffle() {
    _tiles = List.generate(grid * grid, (i) => i); // 0..grid²-1
    _emptyIndex = grid * grid - 1;

    final rng = Random();
    // Shuffle by making 1000 random valid moves (always solvable).
    for (var i = 0; i < 1000; i++) {
      final neighbors = _validMoves();
      if (neighbors.isEmpty) continue;
      final target = neighbors[rng.nextInt(neighbors.length)];
      _swap(_emptyIndex, target);
      _emptyIndex = target;
    }
    _moveCount = 0;
  }

  /// Returns the linear indices of tiles that can slide into the empty cell.
  List<int> _validMoves() {
    final moves = <int>[];
    final row = _emptyIndex ~/ grid;
    final col = _emptyIndex % grid;
    if (row > 0) moves.add(_emptyIndex - grid); // above
    if (row < grid - 1) moves.add(_emptyIndex + grid); // below
    if (col > 0) moves.add(_emptyIndex - 1); // left
    if (col < grid - 1) moves.add(_emptyIndex + 1); // right
    return moves;
  }

  void _swap(int a, int b) {
    final tmp = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = tmp;
  }

  /// Attempts to slide the tile at [tileIndex] into the empty space.
  /// Returns true if the move was legal.
  bool move(int tileIndex) {
    if (!_validMoves().contains(tileIndex)) return false;
    _swap(_emptyIndex, tileIndex);
    _emptyIndex = tileIndex;
    _moveCount++;
    return true;
  }

  /// True when every numbered tile is in its goal position.
  bool get isSolved {
    for (var i = 0; i < _tiles.length; i++) {
      if (_tiles[i] != i) return false;
    }
    return true;
  }

  /// Goal position for tile value [value] (0 = empty cell goes last).
  int goalIndexOf(int value) => value;
}
