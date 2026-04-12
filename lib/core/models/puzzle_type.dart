/// All supported puzzle modes.
enum PuzzleType {
  jigsaw,
  slide,
  rotate,
  spotDifference;

  String get koreanName => switch (this) {
        PuzzleType.jigsaw => '직소 퍼즐',
        PuzzleType.slide => '슬라이드 퍼즐',
        PuzzleType.rotate => '회전 퍼즐',
        PuzzleType.spotDifference => '틀린그림 찾기',
      };

  String get description => switch (this) {
        PuzzleType.jigsaw => '조각을 맞춰보세요!',
        PuzzleType.slide => '밀어서 완성해요!',
        PuzzleType.rotate => '돌려서 맞춰요!',
        PuzzleType.spotDifference => '다른 부분을 찾아요!',
      };

  String get dbValue => switch (this) {
        PuzzleType.jigsaw => 'jigsaw',
        PuzzleType.slide => 'slide',
        PuzzleType.rotate => 'rotate',
        PuzzleType.spotDifference => 'spot_difference',
      };

  static PuzzleType fromDb(String value) => switch (value) {
        'jigsaw' => PuzzleType.jigsaw,
        'slide' => PuzzleType.slide,
        'rotate' => PuzzleType.rotate,
        'spot_difference' => PuzzleType.spotDifference,
        _ => throw ArgumentError('Unknown puzzle type: $value'),
      };
}

/// Three difficulty levels used across all puzzle modes.
enum Difficulty {
  easy,
  medium,
  hard;

  String get koreanName => switch (this) {
        Difficulty.easy => '쉽게 ★',
        Difficulty.medium => '보통 ★★',
        Difficulty.hard => '어려워 ★★★',
      };

  String get dbValue => switch (this) {
        Difficulty.easy => 'easy',
        Difficulty.medium => 'medium',
        Difficulty.hard => 'hard',
      };

  static Difficulty fromDb(String value) => switch (value) {
        'easy' => Difficulty.easy,
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => throw ArgumentError('Unknown difficulty: $value'),
      };

  // ── Jigsaw ──────────────────────────────────────────────────────────────
  int get jigsawCols => switch (this) {
        Difficulty.easy => 2,
        Difficulty.medium => 3,
        Difficulty.hard => 4,
      };

  int get jigsawRows => switch (this) {
        Difficulty.easy => 3,
        Difficulty.medium => 4,
        Difficulty.hard => 5,
      };

  int get jigsawPieceCount => jigsawCols * jigsawRows;

  bool get jigsawShowGuide => this == Difficulty.easy;
  bool get jigsawShowOutline => this == Difficulty.medium;
  bool get jigsawAllowRotation => this == Difficulty.hard;

  // ── Slide ───────────────────────────────────────────────────────────────
  int get slideGrid => switch (this) {
        Difficulty.easy => 3,
        Difficulty.medium => 4,
        Difficulty.hard => 5,
      };

  int get slideTileCount => slideGrid * slideGrid - 1;
  bool get slideShowNumbers => this == Difficulty.easy;

  // ── Rotate ──────────────────────────────────────────────────────────────
  int get rotateGrid => switch (this) {
        Difficulty.easy => 2,
        Difficulty.medium => 3,
        Difficulty.hard => 4,
      };

  int get rotateTileCount => rotateGrid * rotateGrid;

  /// Allowed rotation steps (multiples of 90°). Easy: only 0/180, others: all.
  List<int> get rotateAllowedAngles => switch (this) {
        Difficulty.easy => [0, 180],
        _ => [0, 90, 180, 270],
      };

  // ── Spot the Difference ─────────────────────────────────────────────────
  int get spotDifferenceCount => switch (this) {
        Difficulty.easy => 3,
        Difficulty.medium => 5,
        Difficulty.hard => 7,
      };

  /// Null = no time limit
  int? get spotTimeLimitSeconds => switch (this) {
        Difficulty.easy => null,
        Difficulty.medium => 90,
        Difficulty.hard => 60,
      };
}
