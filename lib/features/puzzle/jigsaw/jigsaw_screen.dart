import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/photo.dart';
import '../../../core/models/puzzle_type.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../shared/utils/jigsaw_clipper.dart';
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
  Uint8List? _imageBytes;
  bool _loading = true;
  int _elapsedSeconds = 0;
  int _hintsUsed = 0;
  bool _showHint = false;
  Timer? _timer;
  double _imageAspectRatio = 1.0;
  JigsawEdgeMap? _edgeMap;
  int get _cols => _edgeMap?.cols ?? 1;
  int get _rows => _edgeMap?.rows ?? 1;

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
    final file = File(widget.photo.filePath);
    final bytes = await file.readAsBytes();

    // Get image dimensions via Flutter's codec (no heavy re-encode)
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final imgW = frame.image.width;
    final imgH = frame.image.height;
    frame.image.dispose();
    final isLandscape = imgW > imgH;

    final cols = isLandscape
        ? widget.difficulty.jigsawRows
        : widget.difficulty.jigsawCols;
    final rows = isLandscape
        ? widget.difficulty.jigsawCols
        : widget.difficulty.jigsawRows;

    final edgeMap = JigsawEdgeMap(cols: cols, rows: rows);
    final pieces = <_Piece>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        pieces.add(_Piece(col: c, row: r));
      }
    }
    pieces.shuffle();

    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _imageAspectRatio = imgW / imgH;
        _edgeMap = edgeMap;
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

  bool get _allPlaced => _pieces?.every((p) => p.isPlaced) ?? false;

  void _onPiecePlaced(_Piece piece) {
    HapticUtils.snap();
    setState(() => piece.isPlaced = true);
    if (_allPlaced) {
      _timer?.cancel();
      HapticUtils.complete();
      Future.delayed(const Duration(milliseconds: 600), _goToCompletion);
    }
  }

  void _onPieceUnplaced(_Piece piece) {
    HapticUtils.pick();
    setState(() => piece.isPlaced = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('${AppStrings.jigsawMode} — ${widget.difficulty.koreanName}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Text(
                TimeUtils.mmss(_elapsedSeconds),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (widget.difficulty != Difficulty.hard &&
              widget.difficulty != Difficulty.expert)
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
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _imageAspectRatio,
                        child: _JigsawBoard(
                          imageBytes: _imageBytes!,
                          cols: _cols,
                          rows: _rows,
                          edgeMap: _edgeMap!,
                          pieces: _pieces!,
                          showHint: _showHint,
                          photo: widget.photo,
                          onPiecePlaced: _onPiecePlaced,
                          onPieceUnplaced: _onPieceUnplaced,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 130,
                  color: AppColors.surfaceVariant,
                  child: _PieceTray(
                    imageBytes: _imageBytes!,
                    cols: _cols,
                    rows: _rows,
                    edgeMap: _edgeMap!,
                    pieces: _pieces!.where((p) => !p.isPlaced).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Piece {
  _Piece({required this.col, required this.row});
  final int col;
  final int row;
  bool isPlaced = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Renders a single jigsaw piece from the full image

class _PieceView extends StatelessWidget {
  const _PieceView({
    required this.imageBytes,
    required this.col,
    required this.row,
    required this.cols,
    required this.rows,
    required this.edgeMap,
    required this.displayWidth,
    required this.displayHeight,
  });

  final Uint8List imageBytes;
  final int col, row, cols, rows;
  final JigsawEdgeMap edgeMap;
  final double displayWidth;
  final double displayHeight;

  @override
  Widget build(BuildContext context) {
    // Cell size within the full board
    final cellW = displayWidth;
    final cellH = displayHeight;

    // Tab overflow padding
    final overflowX = cellW * kTabOverflow;
    final overflowY = cellH * kTabOverflow;

    // Padded piece size (cell + overflow on each side)
    final pieceW = cellW + overflowX * 2;
    final pieceH = cellH + overflowY * 2;

    // Full board size
    final boardW = cellW * cols;
    final boardH = cellH * rows;

    final clipper = edgeMap.clipperFor(row, col,
        padding: EdgeInsets.fromLTRB(overflowX, overflowY, overflowX, overflowY));

    return SizedBox(
      width: pieceW,
      height: pieceH,
      child: ClipPath(
        clipper: clipper,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: boardW,
          maxHeight: boardH,
          child: Transform.translate(
            offset: Offset(
              -(col * cellW - overflowX),
              -(row * cellH - overflowY),
            ),
            child: Image.memory(imageBytes,
                width: boardW, height: boardH, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _JigsawBoard extends StatelessWidget {
  const _JigsawBoard({
    required this.imageBytes,
    required this.cols,
    required this.rows,
    required this.edgeMap,
    required this.pieces,
    required this.showHint,
    required this.photo,
    required this.onPiecePlaced,
    required this.onPieceUnplaced,
  });

  final Uint8List imageBytes;
  final int cols, rows;
  final JigsawEdgeMap edgeMap;
  final List<_Piece> pieces;
  final bool showHint;
  final Photo photo;
  final void Function(_Piece) onPiecePlaced;
  final void Function(_Piece) onPieceUnplaced;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.tileBorder, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd - 1),
        child: LayoutBuilder(builder: (context, constraints) {
          final cellW = constraints.maxWidth / cols;
          final cellH = constraints.maxHeight / rows;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Hint: show full image faintly
              if (showHint)
                Opacity(
                  opacity: 0.25,
                  child: Image.file(File(photo.filePath),
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity),
                ),

              // Cells: outlines for empty, pieces for placed
              for (var r = 0; r < rows; r++)
                for (var c = 0; c < cols; c++)
                  _BoardCell(
                    col: c,
                    row: r,
                    cellW: cellW,
                    cellH: cellH,
                    cols: cols,
                    rows: rows,
                    imageBytes: imageBytes,
                    edgeMap: edgeMap,
                    pieces: pieces,
                    onPiecePlaced: onPiecePlaced,
                    onPieceUnplaced: onPieceUnplaced,
                  ),
            ],
          );
        }),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.col,
    required this.row,
    required this.cellW,
    required this.cellH,
    required this.cols,
    required this.rows,
    required this.imageBytes,
    required this.edgeMap,
    required this.pieces,
    required this.onPiecePlaced,
    required this.onPieceUnplaced,
  });

  final int col, row, cols, rows;
  final double cellW, cellH;
  final Uint8List imageBytes;
  final JigsawEdgeMap edgeMap;
  final List<_Piece> pieces;
  final void Function(_Piece) onPiecePlaced;
  final void Function(_Piece) onPieceUnplaced;

  @override
  Widget build(BuildContext context) {
    final overflowX = cellW * kTabOverflow;
    final overflowY = cellH * kTabOverflow;
    final placed = pieces.where((p) => p.isPlaced && p.col == col && p.row == row);

    if (placed.isNotEmpty) {
      final piece = placed.first;
      return Positioned(
        left: col * cellW - overflowX,
        top: row * cellH - overflowY,
        child: Draggable<_Piece>(
          data: piece,
          onDragStarted: () => onPieceUnplaced(piece),
          feedback: SizedBox(
            width: cellW + overflowX * 2,
            height: cellH + overflowY * 2,
            child: _PieceView(
              imageBytes: imageBytes,
              col: col, row: row, cols: cols, rows: rows,
              edgeMap: edgeMap,
              displayWidth: cellW, displayHeight: cellH,
            ),
          ),
          childWhenDragging: SizedBox(
            width: cellW + overflowX * 2,
            height: cellH + overflowY * 2,
          ),
          child: _PieceView(
            imageBytes: imageBytes,
            col: col, row: row, cols: cols, rows: rows,
            edgeMap: edgeMap,
            displayWidth: cellW, displayHeight: cellH,
          ),
        ),
      );
    }

    // Empty cell: show jigsaw outline + DragTarget
    return Positioned(
      left: col * cellW - overflowX,
      top: row * cellH - overflowY,
      width: cellW + overflowX * 2,
      height: cellH + overflowY * 2,
      child: DragTarget<_Piece>(
        onWillAcceptWithDetails: (d) => d.data.col == col && d.data.row == row,
        onAcceptWithDetails: (d) => onPiecePlaced(d.data),
        builder: (context, candidateData, _) {
          final isHovering = candidateData.isNotEmpty;
          final clipper = edgeMap.clipperFor(row, col,
              padding: EdgeInsets.fromLTRB(overflowX, overflowY, overflowX, overflowY));
          return CustomPaint(
            painter: _JigsawOutlinePainter(
              clipper: clipper,
              color: isHovering ? AppColors.pieceSnap : AppColors.tileBorder.withAlpha(150),
              strokeWidth: isHovering ? 2.5 : 1.2,
              fillColor: isHovering ? AppColors.pieceSnap.withAlpha(40) : null,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _JigsawOutlinePainter extends CustomPainter {
  const _JigsawOutlinePainter({
    required this.clipper,
    required this.color,
    this.strokeWidth = 1.0,
    this.fillColor,
  });

  final JigsawClipper clipper;
  final Color color;
  final double strokeWidth;
  final Color? fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
  }

  @override
  bool shouldRepaint(_JigsawOutlinePainter old) =>
      color != old.color || strokeWidth != old.strokeWidth || fillColor != old.fillColor;
}

// ─────────────────────────────────────────────────────────────────────────────

class _PieceTray extends StatefulWidget {
  const _PieceTray({
    required this.imageBytes,
    required this.cols,
    required this.rows,
    required this.edgeMap,
    required this.pieces,
  });

  final Uint8List imageBytes;
  final int cols, rows;
  final JigsawEdgeMap edgeMap;
  final List<_Piece> pieces;

  @override
  State<_PieceTray> createState() => _PieceTrayState();
}

class _PieceTrayState extends State<_PieceTray> {
  int _page = 0;

  int get _pageSize {
    final w = MediaQuery.of(context).size.width;
    return (w / 120).floor().clamp(2, 8);
  }

  int get _totalPages =>
      (widget.pieces.length / _pageSize).ceil().clamp(1, 999);

  @override
  void didUpdateWidget(_PieceTray old) {
    super.didUpdateWidget(old);
    if (_page >= _totalPages) _page = (_totalPages - 1).clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pieces.isEmpty) {
      return const Center(
        child: Text('모든 조각을 배치했어요!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      );
    }

    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.pieces.length);
    final visible = widget.pieces.sublist(start, end);
    final hasPrev = _page > 0;
    final hasNext = _page < _totalPages - 1;

    // Tray piece display size
    const trayPieceSize = 90.0;
    final cellW = trayPieceSize / (1 + kTabOverflow * 2);
    final cellH = cellW; // square cells in tray for simplicity

    return Row(
      children: [
        IconButton(
          onPressed: hasPrev ? () => setState(() => _page--) : null,
          icon: Icon(Icons.chevron_left_rounded, size: 32,
              color: hasPrev ? AppColors.primary : AppColors.tileBorder),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: visible.map((piece) {
              final pieceView = _PieceView(
                imageBytes: widget.imageBytes,
                col: piece.col, row: piece.row,
                cols: widget.cols, rows: widget.rows,
                edgeMap: widget.edgeMap,
                displayWidth: cellW, displayHeight: cellH,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Draggable<_Piece>(
                  data: piece,
                  feedback: Material(
                    color: Colors.transparent,
                    elevation: 6,
                    child: SizedBox(
                        width: trayPieceSize, height: trayPieceSize,
                        child: pieceView),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: SizedBox(
                        width: trayPieceSize, height: trayPieceSize,
                        child: pieceView),
                  ),
                  child: SizedBox(
                      width: trayPieceSize, height: trayPieceSize,
                      child: pieceView),
                ),
              );
            }).toList(),
          ),
        ),
        IconButton(
          onPressed: hasNext ? () => setState(() => _page++) : null,
          icon: Icon(Icons.chevron_right_rounded, size: 32,
              color: hasNext ? AppColors.primary : AppColors.tileBorder),
        ),
      ],
    );
  }
}
