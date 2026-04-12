import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/models/puzzle_type.dart';

/// Large selectable card for choosing a puzzle mode.
class PuzzleModeCard extends StatelessWidget {
  const PuzzleModeCard({
    super.key,
    required this.type,
    required this.onTap,
    this.isSelected = false,
  });

  final PuzzleType type;
  final VoidCallback onTap;
  final bool isSelected;

  static Color _cardColor(PuzzleType type) => switch (type) {
        PuzzleType.jigsaw => AppColors.jigsaw,
        PuzzleType.slide => AppColors.slide,
        PuzzleType.rotate => AppColors.rotate,
        PuzzleType.spotDifference => AppColors.spotDifference,
      };

  @override
  Widget build(BuildContext context) {
    final color = _cardColor(type);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(220),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon,
                size: AppSizes.iconXl, color: Colors.white),
            const SizedBox(height: AppSizes.sm),
            Text(
              type.koreanName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              type.description,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
