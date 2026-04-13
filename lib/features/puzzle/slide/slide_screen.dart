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
  late final SlideEngine _engine;
  List<Uint8List>? _tiles;
  bool _loading = true;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _engine = SlideEngine(difficulty: widget.difficulty);
    _initPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initPuzzle() async {
    final g = widget.difficulty.slideGrid;
    final tiles = await ImageUtils.sliceIntoTiles(
        File(widget.photo.filePath), g, g);
    _engine.shuffle();
    if (mounted) {
      setState(() {
        _tiles = tiles;
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
    final moved = _engine.move(index);
    if (!moved) {
      HapticUtils.error();
      SoundUtils.error();
      return;
    }
    HapticUtils.snap();
    SoundUtils.snap();
    setState(() {});

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

  String _formatTime() => TimeUtils.mmss(_elapsedSeconds);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingOverlay());

    final g = widget.difficulty.slideGrid;
    final tiles = _tiles!;
    final board = _engine.tiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppStrings.slideMode} — ${widget.difficulty.koreanName}'),
        actions: [
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${AppStrings.moves}: ${_engine.moveCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: g,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: g * g,
              itemBuilder: (_, i) {
                final tileValue = board[i];
                final isEmpty = tileValue == 0;
                final isGoal = tileValue == i && !isEmpty;

                return GestureDetector(
                  onTap: isEmpty ? null : () => _onTileTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? AppColors.tileBackground
                          : null,
                      border: isGoal
                          ? Border.all(
                              color: AppColors.pieceCorrect, width: 2)
                          : Border.all(
                              color: AppColors.tileBorder, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isEmpty
                        ? null
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.memory(
                                  tiles[tileValue],
                                  fit: BoxFit.fill,
                                ),
                              ),
                              if (widget.difficulty.slideShowNumbers)
                                Positioned(
                                  bottom: 2,
                                  right: 4,
                                  child: Text(
                                    '$tileValue',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withAlpha(200),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
