import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/photo.dart';
import '../../core/models/puzzle_type.dart';
import '../../shared/widgets/puzzle_mode_card.dart';
import 'difficulty_selection_screen.dart';

/// The user picks which of the 4 puzzle types to play.
/// Tapping a mode navigates immediately to the difficulty screen.
class PuzzleSelectionScreen extends StatelessWidget {
  const PuzzleSelectionScreen({super.key, required this.photo});

  final Photo photo;

  void _onModeSelected(BuildContext context, PuzzleType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DifficultySelectionScreen(
          photo: photo,
          puzzleType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.choosePuzzle),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Photo thumbnail strip
          Container(
            height: 100,
            margin: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              image: DecorationImage(
                image: FileImage(File(photo.filePath)),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),

          // Mode grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSizes.md,
                crossAxisSpacing: AppSizes.md,
                children: PuzzleType.values.map((type) {
                  return PuzzleModeCard(
                    type: type,
                    onTap: () => _onModeSelected(context, type),
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
