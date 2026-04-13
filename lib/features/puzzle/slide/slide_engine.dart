import 'dart:math';
import 'package:flutter/painting.dart';

/// Slide-puzzle engine (15-puzzle style).
///
/// Tiles are numbered 1..N. The empty cell is represented by 0.
/// Solved state: [1, 2, 3, ..., N, 0] (empty at bottom-right).
class SlideEngine {
  SlideEngine({required this.cols, required this.rows});

  final int cols;
  final int rows;
  int get totalCells => cols * rows;

  late List<int> _tiles;
  int _emptyIndex = 0;
  int _moveCount = 0;

  List<int> get tiles => List.unmodifiable(_tiles);
  int get moveCount => _moveCount;
  int get emptyIndex => _emptyIndex;

  /// Goal state: [1, 2, ..., N, 0]
  void shuffle() {
    _tiles = List.generate(totalCells, (i) => (i + 1) % totalCells);
    _emptyIndex = totalCells - 1;

    final rng = Random();
    for (var i = 0; i < 1000; i++) {
      final neighbors = _validMoves();
      if (neighbors.isEmpty) continue;
      final target = neighbors[rng.nextInt(neighbors.length)];
      _swap(_emptyIndex, target);
      _emptyIndex = target;
    }
    _moveCount = 0;
  }

  List<int> _validMoves() {
    final moves = <int>[];
    final row = _emptyIndex ~/ cols;
    final col = _emptyIndex % cols;
    if (row > 0) moves.add(_emptyIndex - cols);
    if (row < rows - 1) moves.add(_emptyIndex + cols);
    if (col > 0) moves.add(_emptyIndex - 1);
    if (col < cols - 1) moves.add(_emptyIndex + 1);
    return moves;
  }

  void _swap(int a, int b) {
    final tmp = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = tmp;
  }

  /// Check if tile at [index] is adjacent to the empty cell.
  bool canMove(int index) => _validMoves().contains(index);

  /// Move the tile at [index] into the empty space.
  bool move(int index) {
    if (!canMove(index)) return false;
    _swap(_emptyIndex, index);
    _emptyIndex = index;
    _moveCount++;
    return true;
  }

  /// Try to move a tile in [direction] relative to the empty cell.
  /// Returns true if successful.
  bool moveDirection(AxisDirection direction) {
    final row = _emptyIndex ~/ cols;
    final col = _emptyIndex % cols;

    // The tile that should slide INTO the empty space
    int? target;
    switch (direction) {
      case AxisDirection.up:
        if (row < rows - 1) target = _emptyIndex + cols;
        break;
      case AxisDirection.down:
        if (row > 0) target = _emptyIndex - cols;
        break;
      case AxisDirection.left:
        if (col < cols - 1) target = _emptyIndex + 1;
        break;
      case AxisDirection.right:
        if (col > 0) target = _emptyIndex - 1;
        break;
    }

    if (target == null) return false;
    return move(target);
  }

  bool get isSolved {
    for (var i = 0; i < totalCells - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles[totalCells - 1] == 0;
  }
}
