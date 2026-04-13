import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
import 'rotate_engine.dart';

class RotateScreen extends StatefulWidget {
  const RotateScreen({
    super.key,
    required this.photo,
    required this.difficulty,
  });

  final Photo photo;
  final Difficulty difficulty;

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen> {
  late final RotateEngine _engine;
  List<Uint8List>? _tiles;
  bool _loading = true;
  int _elapsedSeconds = 0;
  int _hintsUsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _engine = RotateEngine(difficulty: widget.difficulty);
    _initPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initPuzzle() async {
    final g = widget.difficulty.rotateGrid;
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
    _engine.rotateTile(index);
    HapticUtils.snap();
    SoundUtils.snap();
    setState(() {});
    if (_engine.isSolved) {
      _timer?.cancel();
      HapticUtils.complete();
      SoundUtils.complete();
      Future.delayed(const Duration(milliseconds: 500), _goToCompletion);
    }
  }

  void _goToCompletion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionScreen(
          photo: widget.photo,
          puzzleType: PuzzleType.rotate,
          difficulty: widget.difficulty,
          elapsedSeconds: _elapsedSeconds,
          hintsUsed: _hintsUsed,
        ),
      ),
    );
  }

  String _formatTime() => TimeUtils.mmss(_elapsedSeconds);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingOverlay());

    final g = widget.difficulty.rotateGrid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppStrings.rotateMode} — ${widget.difficulty.koreanName}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${_engine.correctCount}/${g * g} 완성',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Text(
              AppStrings.tapToRotate,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: g,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: g * g,
                    itemBuilder: (_, i) {
                      final tile = _engine.tiles[i];
                      final bytes = _tiles![i];
                      return _RotateTileWidget(
                        bytes: bytes,
                        angle: tile.currentAngle,
                        isCorrect: tile.isCorrect,
                        onTap: () => _onTileTap(i),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RotateTileWidget extends StatefulWidget {
  const _RotateTileWidget({
    required this.bytes,
    required this.angle,
    required this.isCorrect,
    required this.onTap,
  });

  final Uint8List bytes;
  final int angle;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  State<_RotateTileWidget> createState() => _RotateTileWidgetState();
}

class _RotateTileWidgetState extends State<_RotateTileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _rotation;
  double _prevAngle = 0;

  @override
  void initState() {
    super.initState();
    _prevAngle = widget.angle * math.pi / 180;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotation = Tween(begin: _prevAngle, end: _prevAngle).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_RotateTileWidget old) {
    super.didUpdateWidget(old);
    if (old.angle != widget.angle) {
      final targetAngle = widget.angle * math.pi / 180;
      _rotation = Tween(begin: _prevAngle, end: targetAngle).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      );
      _ctrl.forward(from: 0).then((_) => _prevAngle = targetAngle);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (_, child) => Transform.rotate(
          angle: _rotation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isCorrect
                  ? AppColors.pieceCorrect
                  : AppColors.tileBorder,
              width: widget.isCorrect
                  ? AppSizes.tileCorrectBorderWidth
                  : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.memory(widget.bytes, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}
