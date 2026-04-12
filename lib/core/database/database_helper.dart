import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/photo.dart';
import '../models/puzzle_record.dart';
import '../models/settings.dart';
import '../models/user_profile.dart';

/// Singleton SQLite database helper.
///
/// Schema mirrors the GDD section 8-3:
///   photos, puzzles, user_profile, settings
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'snappuzzle.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        width_px INTEGER NOT NULL DEFAULT 1024,
        height_px INTEGER NOT NULL DEFAULT 1024
      )
    ''');

    await db.execute('''
      CREATE TABLE puzzles (
        id TEXT PRIMARY KEY,
        photo_id TEXT NOT NULL,
        type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        best_stars INTEGER NOT NULL DEFAULT 0,
        best_time_seconds INTEGER,
        total_moves INTEGER,
        hints_used INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        total_stars INTEGER NOT NULL DEFAULT 0,
        total_puzzles_completed INTEGER NOT NULL DEFAULT 0,
        play_time_today_seconds INTEGER NOT NULL DEFAULT 0,
        last_play_date TEXT
      )
    ''');

    // Seed a single profile row
    await db.insert('user_profile', {
      'id': 1,
      'total_stars': 0,
      'total_puzzles_completed': 0,
      'play_time_today_seconds': 0,
      'last_play_date': null,
    });

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        daily_limit_minutes INTEGER,
        camera_enabled INTEGER NOT NULL DEFAULT 1,
        save_to_gallery INTEGER NOT NULL DEFAULT 0,
        pin TEXT,
        high_contrast_mode INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed default settings
    await db.insert('settings', {
      'id': 1,
      'daily_limit_minutes': null,
      'camera_enabled': 1,
      'save_to_gallery': 0,
      'pin': null,
      'high_contrast_mode': 0,
    });
  }

  // ── Photos ───────────────────────────────────────────────────────────────

  Future<void> insertPhoto(Photo photo) async {
    final db = await database;
    await db.insert(
      'photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Photo>> getAllPhotos() async {
    final db = await database;
    final maps = await db.query('photos', orderBy: 'created_at DESC');
    return maps.map(Photo.fromMap).toList();
  }

  Future<Photo?> getPhoto(String id) async {
    final db = await database;
    final maps = await db.query('photos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Photo.fromMap(maps.first);
  }

  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  // ── Puzzle Records ───────────────────────────────────────────────────────

  Future<void> upsertPuzzleRecord(PuzzleRecord record) async {
    final db = await database;
    // Keep the record with the most stars (or latest if stars equal).
    final existing = await db.query(
      'puzzles',
      where: 'photo_id = ? AND type = ? AND difficulty = ?',
      whereArgs: [record.photoId, record.type.dbValue, record.difficulty.dbValue],
    );

    if (existing.isEmpty) {
      await db.insert('puzzles', record.toMap());
    } else {
      final prev = PuzzleRecord.fromMap(existing.first);
      if (record.bestStars > prev.bestStars ||
          (record.bestStars == prev.bestStars &&
              record.bestTimeSeconds != null &&
              prev.bestTimeSeconds != null &&
              record.bestTimeSeconds! < prev.bestTimeSeconds!)) {
        await db.update(
          'puzzles',
          record.toMap(),
          where: 'id = ?',
          whereArgs: [prev.id],
        );
      }
    }
  }

  Future<List<PuzzleRecord>> getPuzzlesForPhoto(String photoId) async {
    final db = await database;
    final maps = await db.query(
      'puzzles',
      where: 'photo_id = ?',
      whereArgs: [photoId],
    );
    return maps.map(PuzzleRecord.fromMap).toList();
  }

  Future<List<PuzzleRecord>> getAllPuzzleRecords() async {
    final db = await database;
    final maps =
        await db.query('puzzles', orderBy: 'completed_at DESC');
    return maps.map(PuzzleRecord.fromMap).toList();
  }

  // ── User Profile ─────────────────────────────────────────────────────────

  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profile', where: 'id = 1');
    if (maps.isEmpty) return const UserProfile();
    return UserProfile.fromMap(maps.first);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await database;
    await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = 1',
    );
  }

  Future<void> addStars(int stars) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE user_profile SET total_stars = total_stars + ?, '
      'total_puzzles_completed = total_puzzles_completed + 1 WHERE id = 1',
      [stars],
    );
  }

  Future<void> addPlayTime(int seconds) async {
    final db = await database;
    final now = DateTime.now();
    final profile = await getUserProfile();

    // Reset daily timer if it's a new day
    final isNewDay = profile.lastPlayDate == null ||
        !_isSameDay(profile.lastPlayDate!, now);

    if (isNewDay) {
      await db.update(
        'user_profile',
        {'play_time_today_seconds': seconds, 'last_play_date': now.toIso8601String()},
        where: 'id = 1',
      );
    } else {
      await db.rawUpdate(
        'UPDATE user_profile SET play_time_today_seconds = play_time_today_seconds + ?, '
        'last_play_date = ? WHERE id = 1',
        [seconds, now.toIso8601String()],
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<AppSettings> getSettings() async {
    final db = await database;
    final maps = await db.query('settings', where: 'id = 1');
    if (maps.isEmpty) return const AppSettings();
    return AppSettings.fromMap(maps.first);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await database;
    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}
