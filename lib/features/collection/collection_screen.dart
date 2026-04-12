import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/puzzle_type.dart';
import '../../shared/widgets/level_badge.dart';
import '../../shared/widgets/star_display.dart';
import '../home/home_provider.dart';
import '../puzzle/puzzle_selection_screen.dart';
import 'collection_provider.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumProvider);
    final profileAsync = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.albumTitle),
      ),
      body: profileAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (profile) => Column(
          children: [
            // Level progress bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.md),
              child: LevelProgressBar(profile: profile),
            ),
            const Divider(height: 1),

            // Album grid
            Expanded(
              child: albumAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: Text(
                          AppStrings.albumEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSizes.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSizes.md,
                      crossAxisSpacing: AppSizes.md,
                      childAspectRatio:
                          AppSizes.collectionCardWidth /
                              AppSizes.collectionCardHeight,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _AlbumCard(
                      entry: entries[i],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.entry});

  final AlbumEntry entry;

  @override
  Widget build(BuildContext context) {
    final allDone = entry.allModesCompleted;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PuzzleSelectionScreen(photo: entry.photo),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: allDone
              ? Border.all(color: AppColors.goldFrame, width: 3)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              Image.file(
                File(entry.photo.thumbnailPath),
                fit: BoxFit.cover,
              ),

              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),

              // Gold frame badge
              if (allDone)
                Positioned(
                  top: AppSizes.xs,
                  right: AppSizes.xs,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.goldFrame,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),

              // Mode badges
              Positioned(
                top: AppSizes.xs,
                left: AppSizes.xs,
                child: Wrap(
                  spacing: 2,
                  children: PuzzleType.values.map((t) {
                    final done = entry.completedTypes.contains(t);
                    return _ModeBadge(type: t, done: done);
                  }).toList(),
                ),
              ),

              // Stars + date
              Positioned(
                bottom: AppSizes.sm,
                left: AppSizes.sm,
                right: AppSizes.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarDisplay(
                      stars: entry.totalStars.clamp(0, 3),
                      size: 16,
                    ),
                    Text(
                      _formatDate(entry.photo.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.type, required this.done});

  final PuzzleType type;
  final bool done;

  static IconData _icon(PuzzleType t) => switch (t) {
        PuzzleType.jigsaw => Icons.extension_rounded,
        PuzzleType.slide => Icons.grid_view_rounded,
        PuzzleType.rotate => Icons.rotate_right_rounded,
        PuzzleType.spotDifference => Icons.find_in_page_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.pieceCorrect
            : Colors.black.withAlpha(120),
      ),
      child: Icon(_icon(type), size: 12, color: Colors.white),
    );
  }
}

extension on int {
  int clamp(int low, int high) => this < low ? low : this > high ? high : this;
}
