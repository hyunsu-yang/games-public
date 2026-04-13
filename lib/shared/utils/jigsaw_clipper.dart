import 'dart:math';
import 'package:flutter/material.dart';

/// Describes the shape of one edge of a jigsaw piece.
enum EdgeShape { flat, tab, blank }

/// How much a tab protrudes beyond the cell boundary, as a fraction of edge length.
const double kTabOverflow = 0.25;

/// Generates a jigsaw clip path for a piece within a padded bounding box.
///
/// The piece's "cell" is inset by [padding] on each side.
/// Tabs extend outward into the padding area; blanks cut inward from the cell.
class JigsawClipper extends CustomClipper<Path> {
  JigsawClipper({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
    this.padding = EdgeInsets.zero,
  });

  final EdgeShape top;
  final EdgeShape right;
  final EdgeShape bottom;
  final EdgeShape left;
  final EdgeInsets padding;

  @override
  Path getClip(Size size) {
    // Cell rectangle (inside padding)
    final cx = padding.left;
    final cy = padding.top;
    final cw = size.width - padding.left - padding.right;
    final ch = size.height - padding.top - padding.bottom;

    final path = Path();
    path.moveTo(cx, cy);

    // Top edge (left → right)
    _drawEdge(path, cx, cy, cx + cw, cy, top);
    // Right edge (top → bottom)
    _drawEdge(path, cx + cw, cy, cx + cw, cy + ch, right);
    // Bottom edge (right → left)
    _drawEdge(path, cx + cw, cy + ch, cx, cy + ch, bottom);
    // Left edge (bottom → top)
    _drawEdge(path, cx, cy + ch, cx, cy, left);

    path.close();
    return path;
  }

  void _drawEdge(
      Path path, double x1, double y1, double x2, double y2, EdgeShape shape) {
    if (shape == EdgeShape.flat) {
      path.lineTo(x2, y2);
      return;
    }

    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    // Unit vector along edge
    final ux = dx / len;
    final uy = dy / len;

    // Outward perpendicular for clockwise winding: (uy, -ux)
    // Tab protrudes outward; blank indents inward
    final sign = shape == EdgeShape.tab ? 1.0 : -1.0;
    final nx = uy * sign;
    final ny = -ux * sign;

    // Knob geometry
    final neckPos = 0.38; // where neck starts (fraction of edge)
    final neckEnd = 0.62; // where neck ends
    final neckDepth = len * 0.05; // how far neck pulls in before widening
    final headW = len * 0.15; // half-width of the round head
    final headH = len * kTabOverflow; // how far head extends from edge

    // Points along the edge
    final mid = 0.5;

    // A: neck start on edge
    final ax = x1 + ux * len * neckPos;
    final ay = y1 + uy * len * neckPos;

    // B: neck inward (narrowing)
    final bx = ax + nx * neckDepth;
    final by = ay + ny * neckDepth;

    // C: head start (left side of knob)
    final cx = x1 + ux * len * (mid - headW / len) + nx * headH * 0.6;
    final cy = y1 + uy * len * (mid - headW / len) + ny * headH * 0.6;

    // D: head peak left
    final dlx = x1 + ux * len * (mid - headW * 1.1 / len) + nx * headH;
    final dly = y1 + uy * len * (mid - headW * 1.1 / len) + ny * headH;

    // E: head peak center
    final ex = x1 + ux * len * mid + nx * headH * 1.05;
    final ey = y1 + uy * len * mid + ny * headH * 1.05;

    // F: head peak right
    final frx = x1 + ux * len * (mid + headW * 1.1 / len) + nx * headH;
    final fry = y1 + uy * len * (mid + headW * 1.1 / len) + ny * headH;

    // G: head end (right side of knob)
    final gx = x1 + ux * len * (mid + headW / len) + nx * headH * 0.6;
    final gy = y1 + uy * len * (mid + headW / len) + ny * headH * 0.6;

    // H: neck end inward
    final hx = x1 + ux * len * neckEnd + nx * neckDepth;
    final hy = y1 + uy * len * neckEnd + ny * neckDepth;

    // I: neck end on edge
    final ix = x1 + ux * len * neckEnd;
    final iy = y1 + uy * len * neckEnd;

    // Draw the path
    path.lineTo(ax, ay);
    path.cubicTo(bx, by, cx, cy, dlx, dly);
    path.cubicTo(
      dlx + nx * headH * 0.15 + ux * headW * 0.4,
      dly + ny * headH * 0.15 + uy * headW * 0.4,
      ex - ux * headW * 0.2,
      ey - uy * headW * 0.2,
      ex,
      ey,
    );
    path.cubicTo(
      ex + ux * headW * 0.2,
      ey + uy * headW * 0.2,
      frx + nx * headH * 0.15 - ux * headW * 0.4,
      fry + ny * headH * 0.15 - uy * headW * 0.4,
      frx,
      fry,
    );
    path.cubicTo(gx, gy, hx, hy, ix, iy);
    path.lineTo(x2, y2);
  }

  @override
  bool shouldReclip(JigsawClipper old) =>
      top != old.top ||
      right != old.right ||
      bottom != old.bottom ||
      left != old.left ||
      padding != old.padding;
}

/// Generates the edge shapes for a [cols]×[rows] jigsaw grid.
class JigsawEdgeMap {
  JigsawEdgeMap({required this.cols, required this.rows, int seed = 42}) {
    final rng = Random(seed);
    _hEdges = List.generate(
      rows - 1,
      (_) => List.generate(
          cols, (_) => rng.nextBool() ? EdgeShape.tab : EdgeShape.blank),
    );
    _vEdges = List.generate(
      rows,
      (_) => List.generate(
          cols - 1, (_) => rng.nextBool() ? EdgeShape.tab : EdgeShape.blank),
    );
  }

  final int cols;
  final int rows;
  late final List<List<EdgeShape>> _hEdges;
  late final List<List<EdgeShape>> _vEdges;

  EdgeShape _opposite(EdgeShape s) =>
      s == EdgeShape.tab ? EdgeShape.blank : EdgeShape.tab;

  /// Get the edge shapes for piece at (row, col).
  ({EdgeShape top, EdgeShape right, EdgeShape bottom, EdgeShape left})
      edgesFor(int row, int col) {
    return (
      top: row == 0 ? EdgeShape.flat : _opposite(_hEdges[row - 1][col]),
      bottom: row == rows - 1 ? EdgeShape.flat : _hEdges[row][col],
      left: col == 0 ? EdgeShape.flat : _opposite(_vEdges[row][col - 1]),
      right: col == cols - 1 ? EdgeShape.flat : _vEdges[row][col],
    );
  }

  /// Get a clipper for piece at (row, col) with optional padding.
  JigsawClipper clipperFor(int row, int col, {EdgeInsets padding = EdgeInsets.zero}) {
    final e = edgesFor(row, col);
    return JigsawClipper(
        top: e.top, right: e.right, bottom: e.bottom, left: e.left,
        padding: padding);
  }
}
