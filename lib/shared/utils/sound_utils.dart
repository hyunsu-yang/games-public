import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Synthesised sound effects — no external audio files needed.
///
/// Call [init] once at app startup to pre-generate WAV data.
/// Each play method mirrors [HapticUtils] semantics.
abstract final class SoundUtils {
  static const _sampleRate = 44100;
  static final Map<String, Uint8List> _sounds = {};
  static final _players = List.generate(3, (_) => AudioPlayer());
  static int _nextPlayer = 0;
  static bool _initialized = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;
    _sounds['pick'] = _sweep(500, 700, 0.08, 0.3);
    _sounds['snap'] = _tone(1000, 0.12, 0.4, decay: true);
    _sounds['complete'] = _chord([523, 659, 784], 0.4, 0.3);
    _sounds['error'] = _tone(250, 0.15, 0.25);
    _sounds['star'] = _tone(1200, 0.15, 0.35, decay: true);
    _initialized = true;
  }

  static Future<void> dispose() async {
    for (final p in _players) {
      await p.dispose();
    }
  }

  // ── Play methods ───────────────────────────────────────────────────────

  /// Rising tone — picking up a puzzle piece.
  static Future<void> pick() => _play('pick');

  /// Short ping — piece snapped into place or valid move.
  static Future<void> snap() => _play('snap');

  /// Ascending chord — puzzle completed.
  static Future<void> complete() => _play('complete');

  /// Low tone — wrong tap or invalid move.
  static Future<void> error() => _play('error');

  /// Bright chime — star awarded.
  static Future<void> star() => _play('star');

  static Future<void> _play(String name) async {
    final bytes = _sounds[name];
    if (bytes == null) return;
    final player = _players[_nextPlayer];
    _nextPlayer = (_nextPlayer + 1) % _players.length;
    try {
      await player.stop();
      await player.play(BytesSource(bytes));
    } catch (_) {
      // Gracefully ignore audio failures on devices without speakers
    }
  }

  // ── WAV synthesis ──────────────────────────────────────────────────────

  /// Single frequency tone with optional exponential decay.
  static Uint8List _tone(
      double freq, double duration, double volume,
      {bool decay = false}) {
    final n = (_sampleRate * duration).toInt();
    final samples = Float64List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      var env = 1.0;
      if (t < 0.005) env = t / 0.005; // attack
      if (decay) env *= 1 - i / n; // decay
      final tail = duration - t;
      if (tail < 0.01) env *= tail / 0.01; // release
      samples[i] = sin(2 * pi * freq * t) * volume * env;
    }
    return _encodeWav(samples);
  }

  /// Frequency sweep from [startHz] to [endHz].
  static Uint8List _sweep(
      double startHz, double endHz, double duration, double volume) {
    final n = (_sampleRate * duration).toInt();
    final samples = Float64List(n);
    double phase = 0;
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final freq = startHz + (endHz - startHz) * progress;
      var env = 1.0;
      if (t < 0.005) env = t / 0.005;
      final tail = duration - t;
      if (tail < 0.01) env *= tail / 0.01;
      phase += 2 * pi * freq / _sampleRate;
      samples[i] = sin(phase) * volume * env;
    }
    return _encodeWav(samples);
  }

  /// Multi-frequency chord with soft attack/release.
  static Uint8List _chord(
      List<double> freqs, double duration, double volume) {
    final n = (_sampleRate * duration).toInt();
    final samples = Float64List(n);
    final perVol = volume / freqs.length;
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      var env = 1.0;
      if (t < 0.01) env = t / 0.01;
      final tail = duration - t;
      if (tail < 0.05) env *= tail / 0.05;
      double val = 0;
      for (final f in freqs) {
        val += sin(2 * pi * f * t) * perVol * env;
      }
      samples[i] = val;
    }
    return _encodeWav(samples);
  }

  /// Encode raw PCM samples as 16-bit mono WAV.
  static Uint8List _encodeWav(Float64List samples) {
    final dataSize = samples.length * 2;
    final buf = ByteData(44 + dataSize);

    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        buf.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    // RIFF header
    ascii(0, 'RIFF');
    buf.setUint32(4, 36 + dataSize, Endian.little);
    ascii(8, 'WAVE');
    // fmt chunk
    ascii(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little); // PCM
    buf.setUint16(22, 1, Endian.little); // mono
    buf.setUint32(24, _sampleRate, Endian.little);
    buf.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
    buf.setUint16(32, 2, Endian.little); // block align
    buf.setUint16(34, 16, Endian.little); // bits per sample
    // data chunk
    ascii(36, 'data');
    buf.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final s = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      buf.setInt16(44 + i * 2, s, Endian.little);
    }

    return buf.buffer.asUint8List();
  }
}
