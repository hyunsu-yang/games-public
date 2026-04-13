import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/settings.dart';

/// Mutable notifier that keeps the in-memory user profile in sync
/// with the database after puzzle completions or play-time updates.
class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return DatabaseHelper.instance.getUserProfile();
  }

  Future<void> addStars(int stars) async {
    await DatabaseHelper.instance.addStars(stars);
    ref.invalidateSelf();
  }

  Future<void> addPlayTime(int seconds) async {
    await DatabaseHelper.instance.addPlayTime(seconds);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final userProfileNotifierProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(
        UserProfileNotifier.new);

/// Mutable notifier for settings.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return DatabaseHelper.instance.getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await DatabaseHelper.instance.updateSettings(settings);
    ref.invalidateSelf();
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
        SettingsNotifier.new);
