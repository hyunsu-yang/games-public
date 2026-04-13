import '../../core/models/puzzle_type.dart';

/// Calculates the star rating (1-3) for a completed puzzle.
///
/// Rules from GDD section 5-1:
///   ★★★ = no hints + within par time
///   ★★  = ≤1 hint OR par time exceeded
///   ★   = puzzle completed (always guaranteed)
abstract final class StarCalculator {
  // Par times in seconds per difficulty
  static const Map<Difficulty, int> _parTimes = {
    Difficulty.easy: 120,
    Difficulty.medium: 240,
    Difficulty.hard: 420,
    Difficulty.expert: 720,
  };

  static int calculate({
    required Difficulty difficulty,
    required int elapsedSeconds,
    required int hintsUsed,
    int? totalMoves, // slide puzzle only
  }) {
    final parTime = _parTimes[difficulty]!;
    final withinPar = elapsedSeconds <= parTime;
    final noHints = hintsUsed == 0;

    if (withinPar && noHints) return 3;
    if (hintsUsed <= 1 || withinPar) return 2;
    return 1; // always at least 1
  }

  /// Slide-specific calculation uses move count instead of hints.
  static int calculateSlide({
    required Difficulty difficulty,
    required int elapsedSeconds,
    required int totalMoves,
  }) {
    // Par move counts
    final parMoves = switch (difficulty) {
      Difficulty.easy => 50,
      Difficulty.medium => 120,
      Difficulty.hard => 250,
      Difficulty.expert => 500,
    };
    final parTime = _parTimes[difficulty]!;

    final underPar = totalMoves <= parMoves && elapsedSeconds <= parTime;
    final decent = totalMoves <= parMoves * 1.5;

    if (underPar) return 3;
    if (decent) return 2;
    return 1;
  }

  static String starsToString(int stars) => '★' * stars + '☆' * (3 - stars);
}
