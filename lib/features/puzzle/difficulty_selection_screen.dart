import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/photo.dart';
import '../../core/models/puzzle_type.dart';
import 'jigsaw/jigsaw_screen.dart';
import 'slide/slide_screen.dart';
import 'rotate/rotate_screen.dart';
import 'spot_difference/spot_difference_screen.dart';

/// Tapping a difficulty tile starts the puzzle immediately.
class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({
    super.key,
    required this.photo,
    required this.puzzleType,
  });

  final Photo photo;
  final PuzzleType puzzleType;

  static const _descriptions = {
    Difficulty.easy: AppStrings.easyDesc,
    Difficulty.medium: AppStrings.mediumDesc,
    Difficulty.hard: AppStrings.hardDesc,
    Difficulty.expert: AppStrings.expertDesc,
  };

  static const _colors = {
    Difficulty.easy: AppColors.easy,
    Difficulty.medium: AppColors.medium,
    Difficulty.hard: AppColors.hard,
    Difficulty.expert: AppColors.expert,
  };

  void _start(BuildContext context, Difficulty diff) {
    final route = switch (puzzleType) {
      PuzzleType.jigsaw => MaterialPageRoute(
          builder: (_) => JigsawScreen(photo: photo, difficulty: diff)),
      PuzzleType.slide => MaterialPageRoute(
          builder: (_) => SlideScreen(photo: photo, difficulty: diff)),
      PuzzleType.rotate => MaterialPageRoute(
          builder: (_) => RotateScreen(photo: photo, difficulty: diff)),
      PuzzleType.spotDifference => MaterialPageRoute(
          builder: (_) =>
              SpotDifferenceScreen(photo: photo, difficulty: diff)),
    };
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${puzzleType.koreanName} — ${AppStrings.chooseDifficulty}'),
      ),
      body: Column(
        children: [
          // Preview
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Image.file(
                File(photo.thumbnailPath),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Difficulty tiles
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: Difficulty.values.map((d) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    child: _DifficultyTile(
                      difficulty: d,
                      description: _descriptions[d]!,
                      color: _colors[d]!,
                      onTap: () => _start(context, d),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final Difficulty difficulty;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.minTouchTarget * 1.8,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: Row(
          children: [
            Icon(Icons.stars_rounded, color: color, size: AppSizes.iconLg),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.koreanName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded,
                color: color, size: AppSizes.iconMd),
          ],
        ),
      ),
    );
  }
}
