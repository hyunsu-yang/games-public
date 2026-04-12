import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../../../core/models/puzzle_type.dart';
import '../../../shared/utils/image_utils.dart';

/// A single jigsaw piece — holds its image tile, target position,
/// current drag position, and orientation state.
class JigsawPiece {
  JigsawPiece({
    required this.index,
    required this.imageBytes,
    required this.targetCol,
    required this.targetRow,
    required this.targetOffset,
    required this.currentOffset,
    this.rotationDeg = 0,
    this.isPlaced = false,
  });

  final int index;
  final Uint8List imageBytes;
  final int targetCol;
  final int targetRow;
  Offset targetOffset;
  Offset currentOffset;
  int rotationDeg; // 0 | 90 | 180 | 270
  bool isPlaced;

  bool isNearTarget(double threshold) =>
      (currentOffset - targetOffset).distance < threshold;

  JigsawPiece copyWith({
    Offset? currentOffset,
    int? rotationDeg,
    bool? isPlaced,
  }) =>
      JigsawPiece(
        index: index,
        imageBytes: imageBytes,
        targetCol: targetCol,
        targetRow: targetRow,
        targetOffset: targetOffset,
        currentOffset: currentOffset ?? this.currentOffset,
        rotationDeg: rotationDeg ?? this.rotationDeg,
        isPlaced: isPlaced ?? this.isPlaced,
      );
}

/// Generates the initial jigsaw state from an image file.
class JigsawEngine {
  static Future<List<JigsawPiece>> generatePieces({
    required String imagePath,
    required Difficulty difficulty,
    required Size boardSize,
  }) async {
    final cols = difficulty.jigsawCols;
    final rows = difficulty.jigsawRows;

    final tiles = await ImageUtils.sliceIntoTiles(
      File(imagePath),
      cols,
      rows,
    );

    final tileW = boardSize.width / cols;
    final tileH = boardSize.height / rows;
    final rng = Random();
    final pieces = <JigsawPiece>[];

    for (var i = 0; i < tiles.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final targetOffset = Offset(col * tileW, row * tileH);

      final scatterX =
          rng.nextDouble() * (boardSize.width - tileW);
      final scatterY =
          boardSize.height + 20 + rng.nextDouble() * 200;

      final initialRot = difficulty.jigsawAllowRotation
          ? [0, 90, 180, 270][rng.nextInt(4)]
          : 0;

      pieces.add(JigsawPiece(
        index: i,
        imageBytes: tiles[i],
        targetCol: col,
        targetRow: row,
        targetOffset: targetOffset,
        currentOffset: Offset(scatterX, scatterY),
        rotationDeg: initialRot,
      ));
    }

    pieces.shuffle(rng);
    return pieces;
  }
}
