/// Shared time formatting utilities used across puzzle screens.
abstract final class TimeUtils {
  /// Formats seconds as `mm:ss` (e.g., 65 → "01:05").
  static String mmss(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
