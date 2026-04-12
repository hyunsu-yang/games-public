import 'package:equatable/equatable.dart';

/// Parental-control settings, persisted in `settings` SQLite table.
class AppSettings extends Equatable {
  const AppSettings({
    this.dailyLimitMinutes,
    this.cameraEnabled = true,
    this.saveToGallery = false,
    this.pin,
    this.highContrastMode = false,
  });

  /// null = unlimited
  final int? dailyLimitMinutes;
  final bool cameraEnabled;
  final bool saveToGallery;

  /// 4-digit PIN for parental settings lock; null = unlocked
  final String? pin;

  final bool highContrastMode;

  bool get hasDailyLimit => dailyLimitMinutes != null;
  bool get hasPinLock => pin != null && pin!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'daily_limit_minutes': dailyLimitMinutes,
        'camera_enabled': cameraEnabled ? 1 : 0,
        'save_to_gallery': saveToGallery ? 1 : 0,
        'pin': pin,
        'high_contrast_mode': highContrastMode ? 1 : 0,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        dailyLimitMinutes: map['daily_limit_minutes'] as int?,
        cameraEnabled: (map['camera_enabled'] as int?) == 1,
        saveToGallery: (map['save_to_gallery'] as int?) == 1,
        pin: map['pin'] as String?,
        highContrastMode: (map['high_contrast_mode'] as int?) == 1,
      );

  AppSettings copyWith({
    int? dailyLimitMinutes,
    bool? cameraEnabled,
    bool? saveToGallery,
    String? pin,
    bool? highContrastMode,
    bool clearDailyLimit = false,
    bool clearPin = false,
  }) =>
      AppSettings(
        dailyLimitMinutes:
            clearDailyLimit ? null : (dailyLimitMinutes ?? this.dailyLimitMinutes),
        cameraEnabled: cameraEnabled ?? this.cameraEnabled,
        saveToGallery: saveToGallery ?? this.saveToGallery,
        pin: clearPin ? null : (pin ?? this.pin),
        highContrastMode: highContrastMode ?? this.highContrastMode,
      );

  @override
  List<Object?> get props => [
        dailyLimitMinutes,
        cameraEnabled,
        saveToGallery,
        pin,
        highContrastMode,
      ];
}
