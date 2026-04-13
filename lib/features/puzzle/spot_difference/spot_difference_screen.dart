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
import '../../../shared/utils/image_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../completion_screen.dart';

class SpotDifferenceScreen extends StatefulWidget {
  const SpotDifferenceScreen({
    super.key,
    required this.photo,
    required this.difficulty,
  });

  final Photo photo;
  final Difficulty difficulty;

  @override
  State<SpotDifferenceScreen> createState() =>
      _SpotDifferenceScreenState();
}

class _SpotDifferenceScreenState extends State<SpotDifferenceScreen> {
  bool _loading = true;
  Uint8List? _originalBytes;
  Uint8List? _modifiedBytes;
  List<List<int>> _regions = [];
  int _srcImageWidth = 1;
  int _srcImageHeight = 1;
  final Set<int> _foundIndices = {};
  final List<_TapRipple> _ripples = [];

  int _elapsedSeconds = 0;
  Timer? _timer;

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
    final result = await ImageUtils.generateSpotDifferences(
      File(widget.photo.filePath),
      widget.difficulty.spotDifferenceCount,
    );
    if (mounted) {
      setState(() {
        _originalBytes = result.originalBytes;
        _modifiedBytes = result.modifiedBytes;
        _regions = result.differenceRegions;
        _srcImageWidth = result.imageWidth;
        _srcImageHeight = result.imageHeight;
        _loading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);

      final limit = widget.difficulty.spotTimeLimitSeconds;
      if (limit != null && _elapsedSeconds >= limit) {
        _timer?.cancel();
        _goToCompletion();
      }
    });
  }

  void _onTapImage(Offset localPos, Size renderSize) {
    final scaleX = _srcImageWidth / renderSize.width;
    final scaleY = _srcImageHeight / renderSize.height;
    final tapX = localPos.dx * scaleX;
    final tapY = localPos.dy * scaleY;

    for (var i = 0; i < _regions.length; i++) {
      if (_foundIndices.contains(i)) continue;
      final r = _regions[i];
      final cx = r[0].toDouble();
      final cy = r[1].toDouble();
      final radius = r[2].toDouble();

      final dx = tapX - cx;
      final dy = tapY - cy;
      // 20% extra tolerance for children's taps
      if (dx * dx + dy * dy <= radius * radius * 1.44) {
        HapticUtils.snap();
        final highlightX = cx / scaleX;
        final highlightY = cy / scaleY;
        setState(() {
          _foundIndices.add(i);
          _ripples.add(_TapRipple(
            pos: Offset(highlightX, highlightY),
            key: UniqueKey(),
          ));
        });

        if (_foundIndices.length == _regions.length) {
          _timer?.cancel();
          HapticUtils.complete();
          Future.delayed(
              const Duration(milliseconds: 600), _goToCompletion);
        }
        return;
      }
    }

    // Wrong tap
    HapticUtils.error();
  }

  void _goToCompletion() {
    _ripples.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionScreen(
          photo: widget.photo,
          puzzleType: PuzzleType.spotDifference,
          difficulty: widget.difficulty,
          elapsedSeconds: _elapsedSeconds,
          hintsUsed: 0,
        ),
      ),
    );
  }

  String _formatTime() {
    final limit = widget.difficulty.spotTimeLimitSeconds;
    if (limit != null) {
      final remaining = (limit - _elapsedSeconds).clamp(0, limit);
      return TimeUtils.mmss(remaining);
    }
    return TimeUtils.mmss(_elapsedSeconds);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: LoadingOverlay(message: '비교 이미지 만드는 중...'));
    }

    final total = _regions.length;
    final found = _foundIndices.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppStrings.spotMode} — ${widget.difficulty.koreanName}'),
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
                    '$found / $total ${AppStrings.spotFound}',
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
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _foundIndices.contains(i)
                        ? AppColors.pieceCorrect
                        : AppColors.starEmpty,
                  ),
                );
              }),
            ),
          ),

          // Two image panels side by side
          Expanded(
            child: Row(
              children: [
                // Original (non-interactive)
                Expanded(
                  child: _ImagePanel(
                    bytes: _originalBytes!,
                    label: '원본',
                    foundRegions: const [],
                    srcImageWidth: _srcImageWidth,
                    srcImageHeight: _srcImageHeight,
                    ripples: const [],
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 2),
                // Modified (interactive)
                Expanded(
                  child: _ImagePanel(
                    bytes: _modifiedBytes!,
                    label: '바뀐 사진',
                    foundRegions: _foundIndices
                        .map((i) => _regions[i])
                        .toList(),
                    srcImageWidth: _srcImageWidth,
                    srcImageHeight: _srcImageHeight,
                    ripples: _ripples,
                    onTap: _onTapImage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TapRipple {
  _TapRipple({required this.pos, required this.key});
  final Offset pos;
  final Key key;
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.bytes,
    required this.label,
    required this.foundRegions,
    required this.srcImageWidth,
    required this.srcImageHeight,
    required this.ripples,
    required this.onTap,
  });

  final Uint8List bytes;
  final String label;
  final List<List<int>> foundRegions;
  final int srcImageWidth;
  final int srcImageHeight;
  final List<_TapRipple> ripples;
  final void Function(Offset, Size)? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm, vertical: 2),
          color: AppColors.primary.withAlpha(30),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final renderSize =
                  Size(constraints.maxWidth, constraints.maxHeight);
              final scaleX = renderSize.width / srcImageWidth;
              final scaleY = renderSize.height / srcImageHeight;

              return GestureDetector(
                onTapDown: onTap != null
                    ? (d) => onTap!(d.localPosition, renderSize)
                    : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.fill),

                    // Highlight found differences (circular)
                    ...foundRegions.map((r) {
                      final rw = r[2] * 2 * scaleX;
                      final rh = r[2] * 2 * scaleY;
                      return Positioned(
                        left: r[0] * scaleX - rw / 2,
                        top: r[1] * scaleY - rh / 2,
                        width: rw,
                        height: rh,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.pieceCorrect,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(rw / 2, rh / 2),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Ripple animations
                    ...ripples.map((rip) => _RippleCircle(
                          key: rip.key,
                          center: rip.pos,
                        )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RippleCircle extends StatefulWidget {
  const _RippleCircle({super.key, required this.center});
  final Offset center;

  @override
  State<_RippleCircle> createState() => _RippleCircleState();
}

class _RippleCircleState extends State<_RippleCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final r = AppSizes.spotHighlightRadius * _ctrl.value;
        final opacity = (1 - _ctrl.value).clamp(0.0, 1.0);
        return Positioned(
          left: widget.center.dx - r,
          top: widget.center.dy - r,
          child: Container(
            width: r * 2,
            height: r * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.pieceCorrect
                    .withAlpha((opacity * 255).toInt()),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}
