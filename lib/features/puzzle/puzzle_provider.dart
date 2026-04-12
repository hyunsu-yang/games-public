import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/puzzle_record.dart';

/// Provides all puzzle records for a single photo.
final photoPuzzleRecordsProvider =
    FutureProvider.family<List<PuzzleRecord>, String>((ref, photoId) async {
  return DatabaseHelper.instance.getPuzzlesForPhoto(photoId);
});
