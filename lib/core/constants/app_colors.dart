import 'package:flutter/material.dart';

/// SnapPuzzle color palette — warm pastel tones, child-friendly
abstract final class AppColors {
  // Brand / primary
  static const Color primary = Color(0xFFFF8C42); // warm orange
  static const Color primaryLight = Color(0xFFFFB380);
  static const Color primaryDark = Color(0xFFE06000);

  // Secondary / accent
  static const Color secondary = Color(0xFF5BC0EB); // sky blue
  static const Color secondaryLight = Color(0xFF93D9F5);
  static const Color secondaryDark = Color(0xFF2A9FD0);

  // Background
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF0E0);

  // Stars
  static const Color starGold = Color(0xFFFFD700);
  static const Color starEmpty = Color(0xFFD0C8B0);

  // Puzzle piece states
  static const Color pieceCorrect = Color(0xFF4CAF50);  // green border when correct
  static const Color pieceSnap = Color(0xFFFFEB3B);     // yellow snap highlight
  static const Color pieceSelected = Color(0xFF2196F3);  // blue when held

  // Tile puzzle
  static const Color tileBackground = Color(0xFFEEEEEE);
  static const Color tileBorder = Color(0xFFBDBDBD);

  // Text
  static const Color textPrimary = Color(0xFF3E2723);
  static const Color textSecondary = Color(0xFF795548);
  static const Color textHint = Color(0xFFBCAAA4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Difficulty badge colors
  static const Color easy = Color(0xFF66BB6A);
  static const Color medium = Color(0xFFFFA726);
  static const Color hard = Color(0xFFEF5350);

  // Mode card colors
  static const Color jigsaw = Color(0xFFFF7043);
  static const Color slide = Color(0xFF26C6DA);
  static const Color rotate = Color(0xFFAB47BC);
  static const Color spotDifference = Color(0xFF66BB6A);

  // UI feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  // Collection badges
  static const Color goldFrame = Color(0xFFFFD700);
  static const Color silverFrame = Color(0xFFC0C0C0);

  // Overlay / shadow
  static const Color shadow = Color(0x33000000);
  static const Color overlay = Color(0x80000000);

  // High-contrast mode (accessibility)
  static const Color highContrastBorder = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
}
