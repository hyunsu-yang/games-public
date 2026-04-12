import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/photo.dart';
import '../../core/models/puzzle_record.dart';
import '../../core/models/puzzle_type.dart';

/// Provides all puzzle records for a single photo.
final photoPuzzleRecordsProvider =
    FutureProvider.family<List<PuzzleRecord>, String>((ref, photoId) async {
  return DatabaseHelper.instance.getPuzzlesForPhoto(photoId);
});

/// Shared elapsed-time tracker (seconds since puzzle started).
class PuzzleTimerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void tick() => state++;
  void reset() => state = 0;
}

final puzzleTimerProvider =
    NotifierProvider<PuzzleTimerNotifier, int>(PuzzleTimerNotifier.new);
