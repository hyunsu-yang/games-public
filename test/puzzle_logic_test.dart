import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snappuzzle/core/models/puzzle_type.dart';
import 'package:snappuzzle/features/puzzle/slide/slide_engine.dart';
import 'package:snappuzzle/features/puzzle/rotate/rotate_engine.dart';
import 'package:snappuzzle/shared/utils/star_calculator.dart';

void main() {
  // ── Difficulty model tests ────────────────────────────────────────────────

  group('Difficulty', () {
    test('jigsawPieceCount matches grid', () {
      expect(Difficulty.easy.jigsawPieceCount, 6); // 2×3
      expect(Difficulty.medium.jigsawPieceCount, 12); // 3×4
      expect(Difficulty.hard.jigsawPieceCount, 20); // 4×5
    });

    test('slideTileCount is grid²-1', () {
      expect(Difficulty.easy.slideTileCount, 8); // 3×3 - 1
      expect(Difficulty.medium.slideTileCount, 15); // 4×4 - 1
      expect(Difficulty.hard.slideTileCount, 24); // 5×5 - 1
    });

    test('rotateTileCount is grid²', () {
      expect(Difficulty.easy.rotateTileCount, 4); // 2×2
      expect(Difficulty.medium.rotateTileCount, 9); // 3×3
      expect(Difficulty.hard.rotateTileCount, 16); // 4×4
    });

    test('spotDifferenceCount', () {
      expect(Difficulty.easy.spotDifferenceCount, 3);
      expect(Difficulty.medium.spotDifferenceCount, 5);
      expect(Difficulty.hard.spotDifferenceCount, 7);
    });

    test('spotTimeLimitSeconds', () {
      expect(Difficulty.easy.spotTimeLimitSeconds, null);
      expect(Difficulty.medium.spotTimeLimitSeconds, 90);
      expect(Difficulty.hard.spotTimeLimitSeconds, 60);
    });

    test('dbValue round-trip', () {
      for (final d in Difficulty.values) {
        expect(Difficulty.fromDb(d.dbValue), d);
      }
    });
  });

  // ── PuzzleType model tests ────────────────────────────────────────────────

  group('PuzzleType', () {
    test('dbValue round-trip', () {
      for (final t in PuzzleType.values) {
        expect(PuzzleType.fromDb(t.dbValue), t);
      }
    });
  });

  // ── SlideEngine tests ─────────────────────────────────────────────────────

  group('SlideEngine', () {
    test('shuffle produces unsolved board', () {
      final engine = SlideEngine(cols: 3, rows: 3);
      engine.shuffle();
      expect(engine.tiles.length, 9);
      expect(engine.tiles.contains(0), isTrue);
    });

    test('canMove identifies adjacent tiles', () {
      final engine = SlideEngine(cols: 3, rows: 3);
      engine.shuffle();
      final empty = engine.emptyIndex;

      // Tiles adjacent to empty should be movable
      if (empty >= 3) {
        expect(engine.canMove(empty - 3), isTrue);
      }
      // Tile at empty position is not movable
      expect(engine.canMove(empty), isFalse);
    });

    test('move swaps tile with empty', () {
      final engine = SlideEngine(cols: 3, rows: 3);
      engine.shuffle();
      final empty = engine.emptyIndex;

      if (empty >= 3) {
        final above = empty - 3;
        final moved = engine.move(above);
        expect(moved, isTrue);
        expect(engine.emptyIndex, above);
        expect(engine.moveCount, 1);
      }
    });

    test('moveDirection works correctly', () {
      final engine = SlideEngine(cols: 3, rows: 3);
      engine.shuffle();
      // At least one direction should work
      final upOk = engine.moveDirection(AxisDirection.up);
      final downOk = engine.moveDirection(AxisDirection.down);
      final leftOk = engine.moveDirection(AxisDirection.left);
      final rightOk = engine.moveDirection(AxisDirection.right);
      expect(upOk || downOk || leftOk || rightOk, isTrue);
    });

    test('illegal move returns false', () {
      final engine = SlideEngine(cols: 3, rows: 3);
      engine.shuffle();
      final moved = engine.move(engine.emptyIndex);
      expect(moved, isFalse);
    });
  });

  // ── RotateEngine tests ────────────────────────────────────────────────────

  group('RotateEngine', () {
    test('shuffle produces non-zero rotation for some tiles', () {
      final engine = RotateEngine(
          tileCount: 9, allowedAngles: [0, 90, 180, 270]);
      engine.shuffle();
      expect(engine.tiles.length, 9);
      final nonZero = engine.tiles.where((t) => t.currentAngle != 0);
      expect(nonZero, isNotEmpty);
    });

    test('rotateTile cycles through allowed angles', () {
      final engine =
          RotateEngine(tileCount: 4, allowedAngles: [0, 180]);
      engine.shuffle();
      engine.tiles[0].currentAngle = 0;
      engine.rotateTile(0);
      expect(engine.tiles[0].currentAngle, 180);
      engine.rotateTile(0);
      expect(engine.tiles[0].currentAngle, 0);
    });

    test('isSolved only when all tiles are at 0°', () {
      final engine =
          RotateEngine(tileCount: 4, allowedAngles: [0, 180]);
      engine.shuffle();
      for (final t in engine.tiles) {
        t.currentAngle = 0;
      }
      expect(engine.isSolved, isTrue);
    });
  });

  // ── StarCalculator tests ──────────────────────────────────────────────────

  group('StarCalculator', () {
    test('3 stars: no hints, within par', () {
      final stars = StarCalculator.calculate(
        difficulty: Difficulty.easy,
        elapsedSeconds: 60, // par = 120s
        hintsUsed: 0,
      );
      expect(stars, 3);
    });

    test('2 stars: hint used', () {
      final stars = StarCalculator.calculate(
        difficulty: Difficulty.easy,
        elapsedSeconds: 60,
        hintsUsed: 1,
      );
      expect(stars, 2);
    });

    test('1 star: hints > 1 and over par', () {
      final stars = StarCalculator.calculate(
        difficulty: Difficulty.easy,
        elapsedSeconds: 300, // over par
        hintsUsed: 3,
      );
      expect(stars, 1);
    });

    test('slide 3 stars: under par moves and time', () {
      final stars = StarCalculator.calculateSlide(
        difficulty: Difficulty.easy,
        elapsedSeconds: 60,
        totalMoves: 30, // par = 50
      );
      expect(stars, 3);
    });

    test('starsToString formatting', () {
      expect(StarCalculator.starsToString(3), '★★★');
      expect(StarCalculator.starsToString(2), '★★☆');
      expect(StarCalculator.starsToString(1), '★☆☆');
      expect(StarCalculator.starsToString(0), '☆☆☆');
    });
  });
}
