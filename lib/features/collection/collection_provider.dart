import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_helper.dart';
import '../../core/models/photo.dart';
import '../../core/models/puzzle_record.dart';
import '../../core/models/puzzle_type.dart';

/// Represents a photo card in the collection album.
class AlbumEntry {
  const AlbumEntry({required this.photo, required this.records});

  final Photo photo;
  final List<PuzzleRecord> records;

  /// Which puzzle types have been completed for this photo.
  Set<PuzzleType> get completedTypes =>
      records.where((r) => r.isComplete).map((r) => r.type).toSet();

  bool get allModesCompleted =>
      completedTypes.length == PuzzleType.values.length;

  int get totalStars =>
      records.fold(0, (sum, r) => sum + r.bestStars);

  PuzzleRecord? bestRecord(PuzzleType type) {
    final matches =
        records.where((r) => r.type == type && r.isComplete).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.bestStars.compareTo(a.bestStars));
    return matches.first;
  }
}

/// Delete a photo and its associated puzzle records + files.
Future<void> deleteAlbumEntry(AlbumEntry entry) async {
  // Delete image files from filesystem
  final photoFile = File(entry.photo.filePath);
  final thumbFile = File(entry.photo.thumbnailPath);
  if (photoFile.existsSync()) photoFile.deleteSync();
  if (thumbFile.existsSync()) thumbFile.deleteSync();

  // Delete from DB (CASCADE deletes puzzle records too)
  await DatabaseHelper.instance.deletePhoto(entry.photo.id);
}

final albumProvider = FutureProvider<List<AlbumEntry>>((ref) async {
  final results = await Future.wait([
    DatabaseHelper.instance.getAllPhotos(),
    DatabaseHelper.instance.getAllPuzzleRecords(),
  ]);
  final photos = results[0] as List<Photo>;
  final allRecords = results[1] as List<PuzzleRecord>;

  final recordsByPhoto = <String, List<PuzzleRecord>>{};
  for (final record in allRecords) {
    recordsByPhoto.putIfAbsent(record.photoId, () => []).add(record);
  }

  return photos
      .map((photo) => AlbumEntry(
            photo: photo,
            records: recordsByPhoto[photo.id] ?? [],
          ))
      .toList();
});
