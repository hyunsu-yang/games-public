import 'package:equatable/equatable.dart';

/// Represents a photo taken or selected by the user.
class Photo extends Equatable {
  const Photo({
    required this.id,
    required this.filePath,
    required this.thumbnailPath,
    required this.createdAt,
    this.widthPx = 1024,
    this.heightPx = 1024,
  });

  final String id;
  final String filePath;
  final String thumbnailPath;
  final DateTime createdAt;
  final int widthPx;
  final int heightPx;

  Map<String, dynamic> toMap() => {
        'id': id,
        'file_path': filePath,
        'thumbnail_path': thumbnailPath,
        'created_at': createdAt.toIso8601String(),
        'width_px': widthPx,
        'height_px': heightPx,
      };

  factory Photo.fromMap(Map<String, dynamic> map) => Photo(
        id: map['id'] as String,
        filePath: map['file_path'] as String,
        thumbnailPath: map['thumbnail_path'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        widthPx: (map['width_px'] as int?) ?? 1024,
        heightPx: (map['height_px'] as int?) ?? 1024,
      );

  Photo copyWith({
    String? id,
    String? filePath,
    String? thumbnailPath,
    DateTime? createdAt,
    int? widthPx,
    int? heightPx,
  }) =>
      Photo(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        createdAt: createdAt ?? this.createdAt,
        widthPx: widthPx ?? this.widthPx,
        heightPx: heightPx ?? this.heightPx,
      );

  @override
  List<Object?> get props => [id, filePath, thumbnailPath, createdAt];
}
