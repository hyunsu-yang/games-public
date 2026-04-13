import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/photo.dart';
import '../../../core/models/puzzle_type.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../shared/utils/sound_utils.dart';
import '../../../shared/utils/image_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../completion_screen.dart';

class JigsawScreen extends ConsumerStatefulWidget {
  const JigsawScreen({
    super.key,
    required this.photo,
    required this.difficulty,
  });

  final Photo photo;
  final Difficulty difficulty;

  @override
  ConsumerState<JigsawScreen> createState() => _JigsawScreenState();
}

class _JigsawScreenState extends ConsumerState<JigsawScreen> {
  List<_Piece>? _pieces;
  bool _loading = true;
  int _elapsedSeconds = 0;
  int _hintsUsed = 0;
  bool _showHint = false;
  Timer? _timer;

  // Drag state
  _Piece? _dragging;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initPuzzle() async {
    final cols = widget.difficulty.jigsawCols;
    final rows = widget.difficulty.jigsawRows;

    final tiles = await ImageUtils.sliceIntoTiles(
      File(widget.photo.filePath),
      cols,
      rows,
    );

    // Lay out pieces in a scatter zone below the board
    final pieces = <_Piece>[];
    final rng = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < tiles.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      // Simple random scatter (seeded by timestamp for variety)
      final sx = ((i * 97 + rng) % 280).toDouble();
      final sy = 20.0 + (i * 53 % 100).toDouble();
      pieces.add(_Piece(
        index: i,
        bytes: tiles[i],
        col: col,
        row: row,
        offset: Offset(sx, sy),
        rotationDeg: widget.difficulty.jigsawAllowRotation
            ? [0, 90, 180, 270][(i * 3 + rng) % 4]
            : 0,
      ));
    }

    if (mounted) {
      setState(() {
        _pieces = pieces;
        _loading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  bool get _allPlaced =>
      _pieces?.every((p) => p.isPlaced) ?? false;

  void _onPiecePickUp(_Piece piece, Offset localPos) {
    HapticUtils.pick();
    SoundUtils.pick();
    setState(() {
      _dragging = piece;
      _dragOffset = localPos;
      // Bring to top
      _pieces!
        ..remove(piece)
        ..add(piece);
    });
  }

  void _onPieceDrop(Offset globalPos) {
    if (_dragging == null || _pieces == null) return;

    // Convert global pos to board-local
    final boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return;
    final localPos = boardBox.globalToLocal(globalPos) - _dragOffset;

    final board = boardBox.size;
    final tileW = board.width / widget.difficulty.jigsawCols;
    final tileH = board.height / widget.difficulty.jigsawRows;
    final targetOffset = Offset(
      _dragging!.col * tileW,
      _dragging!.row * tileH,
    );

    final dist = (localPos - targetOffset).distance;
    if (dist < AppSizes.pieceSnapThreshold * 2) {
      HapticUtils.snap();
      SoundUtils.snap();
      setState(() {
        _dragging!
          ..offset = targetOffset
          ..isPlaced = true
          ..rotationDeg = 0;
      });
    } else {
      setState(() => _dragging!.offset = localPos);
    }

    if (_allPlaced) {
      _timer?.cancel();
      HapticUtils.complete();
      SoundUtils.complete();
      Future.delayed(const Duration(milliseconds: 600), _goToCompletion);
    }

    setState(() => _dragging = null);
  }

  void _useHint() {
    setState(() {
      _hintsUsed++;
      _showHint = true;
    });
    Future.delayed(const Duration(seconds: 3),
        () => mounted ? setState(() => _showHint = false) : null);
  }

  void _goToCompletion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionScreen(
          photo: widget.photo,
          puzzleType: PuzzleType.jigsaw,
          difficulty: widget.difficulty,
          elapsedSeconds: _elapsedSeconds,
          hintsUsed: _hintsUsed,
        ),
      ),
    );
  }

  String _formatTime() => TimeUtils.mmss(_elapsedSeconds);

  final _boardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppStrings.jigsawMode} — ${widget.difficulty.koreanName}'),
        actions: [
          // Timer
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Text(
                _formatTime(),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Hint button (only for easy/medium)
          if (widget.difficulty != Difficulty.hard)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded),
              tooltip: AppStrings.hint,
              onPressed: _useHint,
            ),
        ],
      ),
      body: _loading
          ? const LoadingOverlay()
          : Column(
              children: [
                Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.boardPadding),
                      child: AspectRatio(
                        aspectRatio: widget.difficulty.jigsawCols /
                            widget.difficulty.jigsawRows,
                        child: _JigsawBoard(
                          boardKey: _boardKey,
                          photo: widget.photo,
                          difficulty: widget.difficulty,
                          pieces: _pieces ?? [],
                          showHint: _showHint,
                          onPickUp: _onPiecePickUp,
                          onDrop: _onPieceDrop,
                        ),
                      ),
                    ),
                  ),

                Expanded(
                    flex: 2,
                    child: _PieceTray(
                      pieces: _pieces ?? [],
                      tileW: 80,
                      tileH: 80,
                      onPickUp: _onPiecePickUp,
                      onDrop: _onPieceDrop,
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Piece {
  _Piece({
    required this.index,
    required this.bytes,
    required this.col,
    required this.row,
    required this.offset,
    this.rotationDeg = 0,
    this.isPlaced = false,
  });

  final int index;
  final Uint8List bytes;
  final int col;
  final int row;
  Offset offset;
  int rotationDeg;
  bool isPlaced;
}

// ─────────────────────────────────────────────────────────────────────────────

class _JigsawBoard extends StatelessWidget {
  const _JigsawBoard({
    required this.boardKey,
    required this.photo,
    required this.difficulty,
    required this.pieces,
    required this.showHint,
    required this.onPickUp,
    required this.onDrop,
  });

  final GlobalKey boardKey;
  final Photo photo;
  final Difficulty difficulty;
  final List<_Piece> pieces;
  final bool showHint;
  final void Function(_Piece, Offset) onPickUp;
  final void Function(Offset) onDrop;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: boardKey,
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.tileBorder, width: 2),
      ),
      child: Stack(
        children: [
          if (showHint)
            Opacity(
              opacity: 0.25,
              child: Image.file(
                File(photo.filePath),
                fit: BoxFit.fill,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          if (difficulty.jigsawShowGuide)
            CustomPaint(
              painter: _GridPainter(
                cols: difficulty.jigsawCols,
                rows: difficulty.jigsawRows,
              ),
              child: const SizedBox.expand(),
            ),

          ...pieces
              .where((p) => p.isPlaced)
              .map((p) => _PlacedPiece(piece: p)),
        ],
      ),
    );
  }
}

class _PlacedPiece extends StatelessWidget {
  const _PlacedPiece({required this.piece});
  final _Piece piece;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: piece.offset.dx,
      top: piece.offset.dy,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.pieceCorrect, width: 2),
        ),
        child: Image.memory(piece.bytes, fit: BoxFit.fill),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.cols, required this.rows});
  final int cols;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tileBorder.withAlpha(100)
      ..strokeWidth = 1;
    for (var c = 1; c < cols; c++) {
      final x = size.width * c / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var r = 1; r < rows; r++) {
      final y = size.height * r / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.cols != cols || old.rows != rows;
}

// ─────────────────────────────────────────────────────────────────────────────

class _PieceTray extends StatelessWidget {
  const _PieceTray({
    required this.pieces,
    required this.tileW,
    required this.tileH,
    required this.onPickUp,
    required this.onDrop,
  });

  final List<_Piece> pieces;
  final double tileW;
  final double tileH;
  final void Function(_Piece, Offset) onPickUp;
  final void Function(Offset) onDrop;

  @override
  Widget build(BuildContext context) {
    final unplaced = pieces.where((p) => !p.isPlaced).toList();
    return Container(
      color: AppColors.surfaceVariant,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSizes.sm),
        itemCount: unplaced.length,
        itemBuilder: (_, i) {
          final piece = unplaced[i];
          return Padding(
            padding: const EdgeInsets.all(AppSizes.xs),
            child: Draggable<_Piece>(
              data: piece,
              feedback: _DraggingPiece(piece: piece, w: tileW, h: tileH),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _TrayPiece(piece: piece, w: tileW, h: tileH),
              ),
              onDragEnd: (details) => onDrop(details.offset),
              child: GestureDetector(
                onTapDown: (d) => onPickUp(piece, d.localPosition),
                child: _TrayPiece(piece: piece, w: tileW, h: tileH),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrayPiece extends StatelessWidget {
  const _TrayPiece({required this.piece, required this.w, required this.h});
  final _Piece piece;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: piece.rotationDeg * math.pi / 180,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.memory(piece.bytes, fit: BoxFit.fill),
      ),
    );
  }
}

class _DraggingPiece extends StatelessWidget {
  const _DraggingPiece(
      {required this.piece, required this.w, required this.h});
  final _Piece piece;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border:
              Border.all(color: AppColors.pieceSelected, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.memory(piece.bytes, fit: BoxFit.fill),
      ),
    );
  }
}
