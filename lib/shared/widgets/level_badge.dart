import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/models/user_profile.dart';

/// Small badge showing the user's current level and star count.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppColors.starGold,
            size: AppSizes.iconSm,
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            '${profile.totalStars}',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            width: 1,
            height: 16,
            color: AppColors.textOnPrimary.withAlpha(120),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            'Lv.${profile.level}',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal progress bar for the next level.
class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              profile.levelName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${profile.totalStars} / ${profile.starsForNextLevel} ★',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          child: LinearProgressIndicator(
            value: profile.levelProgress,
            minHeight: 10,
            backgroundColor: AppColors.starEmpty,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.starGold),
          ),
        ),
      ],
    );
  }
}
