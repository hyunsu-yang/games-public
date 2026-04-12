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

class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({
    super.key,
    required this.photo,
    required this.puzzleType,
  });

  final Photo photo;
  final PuzzleType puzzleType;

  @override
  State<DifficultySelectionScreen> createState() =>
      _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState
    extends State<DifficultySelectionScreen> {
  Difficulty? _selected;

  static const _descriptions = {
    Difficulty.easy: AppStrings.easyDesc,
    Difficulty.medium: AppStrings.mediumDesc,
    Difficulty.hard: AppStrings.hardDesc,
  };

  static const _colors = {
    Difficulty.easy: AppColors.easy,
    Difficulty.medium: AppColors.medium,
    Difficulty.hard: AppColors.hard,
  };

  void _start() {
    if (_selected == null) return;
    final photo = widget.photo;
    final diff = _selected!;
    final route = switch (widget.puzzleType) {
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
            '${widget.puzzleType.koreanName} — ${AppStrings.chooseDifficulty}'),
      ),
      body: Column(
        children: [
          // Preview
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Image.file(
                File(widget.photo.thumbnailPath),
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
                  final isSelected = _selected == d;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    child: _DifficultyTile(
                      difficulty: d,
                      description: _descriptions[d]!,
                      color: _colors[d]!,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = d),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Start button
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selected == null ? null : _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('시작!'),
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
    required this.isSelected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppSizes.minTouchTarget * 1.8,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(30),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(80),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: isSelected ? Colors.white : color,
              size: AppSizes.iconLg,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.koreanName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withAlpha(220)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: AppSizes.iconMd),
          ],
        ),
      ),
    );
  }
}
