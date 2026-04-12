import 'dart:math';
import 'package:flutter/material.dart';

/// Simple confetti particle burst for puzzle completion.
///
/// Uses a [CustomPainter] and [AnimationController] — no external package needed.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  final _rng = Random();

  static const _particleCount = 80;
  static const _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      });

    _particles = List.generate(
      _particleCount,
      (_) => _Particle(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.2,
        vx: (_rng.nextDouble() - 0.5) * 0.4,
        vy: _rng.nextDouble() * 0.6 + 0.3,
        color: _colors[_rng.nextInt(_colors.length)],
        size: _rng.nextDouble() * 8 + 4,
        rotation: _rng.nextDouble() * pi * 2,
        rotationSpeed: (_rng.nextDouble() - 0.5) * pi,
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final cx = (p.x + p.vx * t) * size.width;
      final cy = (p.y + p.vy * t + 0.5 * t * t) * size.height;
      final opacity = (1.0 - t * 0.8).clamp(0.0, 1.0);
      paint.color = p.color.withAlpha((opacity * 255).toInt());

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
