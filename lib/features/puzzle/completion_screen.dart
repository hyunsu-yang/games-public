import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/photo.dart';
import '../../core/models/puzzle_record.dart';
import '../../core/models/puzzle_type.dart';
import '../../shared/utils/haptic_utils.dart';
import '../../shared/utils/star_calculator.dart';
import '../../shared/utils/time_utils.dart';
import '../../shared/widgets/confetti_overlay.dart';
import '../../shared/widgets/star_display.dart';
import '../home/home_provider.dart';

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({
    super.key,
    required this.photo,
    required this.puzzleType,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.hintsUsed,
    this.totalMoves,
  });

  final Photo photo;
  final PuzzleType puzzleType;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int hintsUsed;
  final int? totalMoves;

  @override
  ConsumerState<CompletionScreen> createState() =>
      _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  late final int _stars;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _stars = widget.puzzleType == PuzzleType.slide && widget.totalMoves != null
        ? StarCalculator.calculateSlide(
            difficulty: widget.difficulty,
            elapsedSeconds: widget.elapsedSeconds,
            totalMoves: widget.totalMoves!,
          )
        : StarCalculator.calculate(
            difficulty: widget.difficulty,
            elapsedSeconds: widget.elapsedSeconds,
            hintsUsed: widget.hintsUsed,
          );
    _saveRecord();
    HapticUtils.complete();
  }

  Future<void> _saveRecord() async {
    if (_saved) return;
    _saved = true;

    // Save puzzle record to DB (shows in album)
    final record = PuzzleRecord(
      id: const Uuid().v4(),
      photoId: widget.photo.id,
      type: widget.puzzleType,
      difficulty: widget.difficulty,
      completedAt: DateTime.now(),
      bestStars: _stars,
      bestTimeSeconds: widget.elapsedSeconds,
      totalMoves: widget.totalMoves,
      hintsUsed: widget.hintsUsed,
    );
    await DatabaseHelper.instance.upsertPuzzleRecord(record);

    // Update user profile stars
    await ref
        .read(userProfileNotifierProvider.notifier)
        .addStars(_stars);
  }

  String _formatTime(int seconds) => TimeUtils.mmss(seconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.xl),

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.starGold.withAlpha(30),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 64,
                    color: AppColors.starGold,
                  ),
                ),

                const SizedBox(height: AppSizes.lg),

                Text(
                  AppStrings.congratulations,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  widget.puzzleType.koreanName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: AppSizes.xl),

                StarDisplay(
                  stars: _stars,
                  size: AppSizes.starSizeLg,
                  animate: true,
                ),

                const SizedBox(height: AppSizes.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      icon: Icons.timer_rounded,
                      label: _formatTime(widget.elapsedSeconds),
                    ),
                    const SizedBox(width: AppSizes.md),
                    if (widget.totalMoves != null)
                      _StatChip(
                        icon: Icons.swap_horiz_rounded,
                        label:
                            '${widget.totalMoves} ${AppStrings.moves}',
                      )
                    else
                      _StatChip(
                        icon: Icons.lightbulb_outline_rounded,
                        label:
                            '힌트 ${widget.hintsUsed}회',
                      ),
                  ],
                ),

                const SizedBox(height: AppSizes.xl),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                  child: Image.file(
                    File(widget.photo.thumbnailPath),
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xl,
                      vertical: AppSizes.lg),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Pop back to puzzle screen to replay
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.replay_rounded),
                          label:
                              const Text(AppStrings.playAgain),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Return all the way home
                            Navigator.popUntil(
                                context, (r) => r.isFirst);
                          },
                          icon: const Icon(Icons.home_rounded),
                          label: const Text(AppStrings.backHome),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ConfettiOverlay(onDone: () {}),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
