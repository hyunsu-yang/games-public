import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
import 'slide_engine.dart';

class SlideScreen extends StatefulWidget {
  const SlideScreen({
    super.key,
    required this.photo,
    required this.difficulty,
  });

  final Photo photo;
  final Difficulty difficulty;

  @override
  State<SlideScreen> createState() => _SlideScreenState();
}

class _SlideScreenState extends State<SlideScreen> {
  late SlideEngine _engine;
  List<Uint8List>? _tiles;
  bool _loading = true;
  int _elapsedSeconds = 0;
  Timer? _timer;
  int _cols = 1;
  int _rows = 1;
  double _imageAspectRatio = 1.0;
  bool _showReference = false;
  // Accumulated pan displacement for the tile currently being swiped.
  Offset _panDelta = Offset.zero;

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
    final g = widget.difficulty.slideGrid;
    final result = await ImageUtils.sliceIntoTiles(
        File(widget.photo.filePath), g, g);
    _engine = SlideEngine(cols: result.cols, rows: result.rows);
    _engine.shuffle();
    if (mounted) {
      setState(() {
        _tiles = result.tiles;
        _cols = result.cols;
        _rows = result.rows;
        _imageAspectRatio = result.aspectRatio;
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

  void _onTileTap(int index) {
    if (_tiles == null) return;
    if (!_engine.canMove(index)) return;
    _engine.move(index);
    HapticUtils.snap();
    SoundUtils.snap();
    setState(() {});
    _checkSolved();
  }

  void _checkSolved() {
    if (_engine.isSolved) {
      _timer?.cancel();
      HapticUtils.complete();
      SoundUtils.complete();
      Future.delayed(const Duration(milliseconds: 400), _goToCompletion);
    }
  }

  void _goToCompletion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionScreen(
          photo: widget.photo,
          puzzleType: PuzzleType.slide,
          difficulty: widget.difficulty,
          elapsedSeconds: _elapsedSeconds,
          hintsUsed: 0,
          totalMoves: _engine.moveCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingOverlay());

    final tiles = _tiles!;
    final board = _engine.tiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppStrings.slideMode} — ${widget.difficulty.koreanName}'),
        actions: [
          // Reference image toggle
          IconButton(
            icon: Icon(_showReference
                ? Icons.image_rounded
                : Icons.image_outlined),
            tooltip: '완성 이미지 보기',
            onPressed: () => setState(() => _showReference = !_showReference),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(TimeUtils.mmss(_elapsedSeconds),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('${AppStrings.moves}: ${_engine.moveCount}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
          children: [
            // Instruction
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Text(
                '빈 칸 옆의 조각을 탭하거나 스와이프하세요',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),

            // Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _imageAspectRatio,
                        child: _buildBoard(tiles, board),
                      ),

                      // Reference image overlay
                      if (_showReference)
                        AspectRatio(
                          aspectRatio: _imageAspectRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              border: Border.all(
                                  color: AppColors.primary, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd - 1),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(widget.photo.filePath),
                                      fit: BoxFit.fill),
                                  Container(
                                    color: Colors.black.withAlpha(100),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '완성 이미지',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
      ),
    );
  }

  /// Decide whether a pan gesture on a tile should trigger a slide.
  ///
  /// Uses accumulated pan displacement as the primary signal and release
  /// velocity as a fallback for quick flings. A velocity-only check misses
  /// slow, deliberate swipes where the finger decelerates to a stop before
  /// lifting — a common pattern that was causing repeated retries.
  void _onTileSwipe(int index, Offset velocity) {
    if (!_engine.canMove(index)) return;
    final emptyIdx = _engine.emptyIndex;

    final tileRow = index ~/ _cols;
    final tileCol = index % _cols;
    final emptyRow = emptyIdx ~/ _cols;
    final emptyCol = emptyIdx % _cols;

    final dCol = emptyCol - tileCol;
    final dRow = emptyRow - tileRow;

    // Component of displacement/velocity pointing toward the empty cell.
    final dirDisp = dCol != 0 ? _panDelta.dx * dCol : _panDelta.dy * dRow;
    final dirVel = dCol != 0 ? velocity.dx * dCol : velocity.dy * dRow;

    const distThreshold = 8.0;       // pixels of drag toward empty
    const velThreshold = 120.0;      // pixels/second fling toward empty

    if (dirDisp > distThreshold || dirVel > velThreshold) {
      _onTileTap(index);
    }
  }

  Widget _buildBoard(List<Uint8List> tiles, List<int> board) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _cols,
        childAspectRatio: _imageAspectRatio * _rows / _cols,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _cols * _rows,
      itemBuilder: (_, i) {
        final tileValue = board[i];
        final isEmpty = tileValue == 0;
        final canMove = _engine.canMove(i);
        final isCorrect = !isEmpty && tileValue == (i + 1) % (_cols * _rows);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canMove ? () => _onTileTap(i) : null,
          onPanStart: canMove ? (_) => _panDelta = Offset.zero : null,
          onPanUpdate: canMove ? (d) => _panDelta += d.delta : null,
          onPanEnd: canMove
              ? (d) => _onTileSwipe(i, d.velocity.pixelsPerSecond)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isEmpty
                  ? AppColors.tileBackground.withAlpha(120)
                  : canMove
                      ? AppColors.primary.withAlpha(25)
                      : null,
              border: isEmpty
                  ? Border.all(
                      color: AppColors.tileBorder.withAlpha(80),
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside)
                  : isCorrect
                      ? Border.all(color: AppColors.pieceCorrect, width: 3)
                      : canMove
                          ? Border.all(color: AppColors.primary, width: 3)
                          : Border.all(
                              color: AppColors.tileBorder.withAlpha(60),
                              width: 1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: canMove && !isEmpty
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isEmpty
                ? Center(
                    child: Icon(Icons.open_with_rounded,
                        size: 24,
                        color: AppColors.tileBorder.withAlpha(150)),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.memory(tiles[tileValue - 1],
                            fit: BoxFit.fill),
                      ),
                      if (widget.difficulty.slideShowNumbers)
                        Positioned(
                          bottom: 2,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$tileValue',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
