/// Spacing, radius, and touch-target constants for SnapPuzzle.
///
/// All touch targets are ≥ 48dp per accessibility guidelines and the GDD.
abstract final class AppSizes {
  // Minimum touch target (48dp)
  static const double minTouchTarget = 48.0;

  // Spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusRound = 100.0;

  // Icon sizes
  static const double iconSm = 20.0;
  static const double iconMd = 28.0;
  static const double iconLg = 40.0;
  static const double iconXl = 56.0;

  // Card
  static const double cardElevation = 4.0;
  static const double cardBorderWidth = 2.0;

  // Puzzle board padding
  static const double boardPadding = 12.0;

  // Jigsaw piece sizes (px, within max 1024x1024 image)
  static const double pieceSnapThreshold = 30.0; // snap magnet distance (px)

  // Rotate puzzle tile border
  static const double tileCorrectBorderWidth = 3.0;

  // Spot-the-difference circle highlight radius
  static const double spotHighlightRadius = 40.0;

  // Collection card
  static const double collectionCardWidth = 160.0;
  static const double collectionCardHeight = 180.0;

  // Home camera button
  static const double cameraButtonSize = 120.0;

  // Star size in reward screen
  static const double starSizeLg = 56.0;
  static const double starSizeMd = 36.0;

  // Image processing
  static const int maxImageDimension = 1024; // pixels
}
