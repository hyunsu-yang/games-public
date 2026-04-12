import 'package:equatable/equatable.dart';
import 'puzzle_type.dart';

/// A completed (or attempted) puzzle run, persisted to SQLite.
class PuzzleRecord extends Equatable {
  const PuzzleRecord({
    required this.id,
    required this.photoId,
    required this.type,
    required this.difficulty,
    required this.completedAt,
    this.bestStars = 0,
    this.bestTimeSeconds,
    this.totalMoves,
    this.hintsUsed = 0,
  });

  final String id;
  final String photoId;
  final PuzzleType type;
  final Difficulty difficulty;
  final DateTime completedAt;
  final int bestStars; // 0-3
  final int? bestTimeSeconds;
  final int? totalMoves; // slide puzzle
  final int hintsUsed;

  bool get isComplete => bestStars > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'photo_id': photoId,
        'type': type.dbValue,
        'difficulty': difficulty.dbValue,
        'completed_at': completedAt.toIso8601String(),
        'best_stars': bestStars,
        'best_time_seconds': bestTimeSeconds,
        'total_moves': totalMoves,
        'hints_used': hintsUsed,
      };

  factory PuzzleRecord.fromMap(Map<String, dynamic> map) => PuzzleRecord(
        id: map['id'] as String,
        photoId: map['photo_id'] as String,
        type: PuzzleType.fromDb(map['type'] as String),
        difficulty: Difficulty.fromDb(map['difficulty'] as String),
        completedAt: DateTime.parse(map['completed_at'] as String),
        bestStars: (map['best_stars'] as int?) ?? 0,
        bestTimeSeconds: map['best_time_seconds'] as int?,
        totalMoves: map['total_moves'] as int?,
        hintsUsed: (map['hints_used'] as int?) ?? 0,
      );

  PuzzleRecord copyWith({
    String? id,
    String? photoId,
    PuzzleType? type,
    Difficulty? difficulty,
    DateTime? completedAt,
    int? bestStars,
    int? bestTimeSeconds,
    int? totalMoves,
    int? hintsUsed,
  }) =>
      PuzzleRecord(
        id: id ?? this.id,
        photoId: photoId ?? this.photoId,
        type: type ?? this.type,
        difficulty: difficulty ?? this.difficulty,
        completedAt: completedAt ?? this.completedAt,
        bestStars: bestStars ?? this.bestStars,
        bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
        totalMoves: totalMoves ?? this.totalMoves,
        hintsUsed: hintsUsed ?? this.hintsUsed,
      );

  @override
  List<Object?> get props =>
      [id, photoId, type, difficulty, bestStars, bestTimeSeconds];
}
