import 'package:flutter/services.dart';

/// Wrapper around [HapticFeedback] with semantically named methods.
abstract final class HapticUtils {
  /// Light tap — picking up a puzzle piece.
  static Future<void> pick() => HapticFeedback.lightImpact();

  /// Medium tap — snapping a piece into the correct slot.
  static Future<void> snap() => HapticFeedback.mediumImpact();

  /// Heavy vibration — puzzle fully completed.
  static Future<void> complete() => HapticFeedback.heavyImpact();

  /// Selection click — tapping a tile or button.
  static Future<void> select() => HapticFeedback.selectionClick();

  /// Soft error tap — wrong placement, gentle negative feedback.
  static Future<void> error() => HapticFeedback.lightImpact();
}
