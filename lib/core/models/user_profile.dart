import 'package:equatable/equatable.dart';

/// User progression stored in the `user_profile` SQLite table.
class UserProfile extends Equatable {
  const UserProfile({
    this.totalStars = 0,
    this.totalPuzzlesCompleted = 0,
    this.playTimeTodaySeconds = 0,
    this.lastPlayDate,
  });

  final int totalStars;
  final int totalPuzzlesCompleted;
  final int playTimeTodaySeconds;
  final DateTime? lastPlayDate;

  int get level => switch (totalStars) {
        < 10 => 1,
        < 30 => 2,
        < 60 => 3,
        < 100 => 4,
        _ => 5,
      };

  String get levelName => switch (level) {
        1 => '퍼즐 초보자',
        2 => '퍼즐 친구',
        3 => '퍼즐 고수',
        4 => '퍼즐 달인',
        _ => '퍼즐 마스터',
      };

  int get starsForNextLevel => switch (level) {
        1 => 10,
        2 => 30,
        3 => 60,
        4 => 100,
        _ => totalStars,
      };

  double get levelProgress {
    if (level >= 5) return 1.0;
    final prev = switch (level) {
      1 => 0,
      2 => 10,
      3 => 30,
      4 => 60,
      _ => 0,
    };
    return (totalStars - prev) / (starsForNextLevel - prev);
  }

  Map<String, dynamic> toMap() => {
        'total_stars': totalStars,
        'total_puzzles_completed': totalPuzzlesCompleted,
        'play_time_today_seconds': playTimeTodaySeconds,
        'last_play_date': lastPlayDate?.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        totalStars: (map['total_stars'] as int?) ?? 0,
        totalPuzzlesCompleted: (map['total_puzzles_completed'] as int?) ?? 0,
        playTimeTodaySeconds: (map['play_time_today_seconds'] as int?) ?? 0,
        lastPlayDate: map['last_play_date'] != null
            ? DateTime.parse(map['last_play_date'] as String)
            : null,
      );

  UserProfile copyWith({
    int? totalStars,
    int? totalPuzzlesCompleted,
    int? playTimeTodaySeconds,
    DateTime? lastPlayDate,
  }) =>
      UserProfile(
        totalStars: totalStars ?? this.totalStars,
        totalPuzzlesCompleted:
            totalPuzzlesCompleted ?? this.totalPuzzlesCompleted,
        playTimeTodaySeconds:
            playTimeTodaySeconds ?? this.playTimeTodaySeconds,
        lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      );

  @override
  List<Object?> get props =>
      [totalStars, totalPuzzlesCompleted, playTimeTodaySeconds, lastPlayDate];
}
