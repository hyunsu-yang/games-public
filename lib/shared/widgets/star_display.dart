import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Displays 1-3 filled/empty star icons.
class StarDisplay extends StatelessWidget {
  const StarDisplay({
    super.key,
    required this.stars,
    this.size = AppSizes.starSizeMd,
    this.animate = false,
  });

  final int stars; // 0-3
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return _StarIcon(
          filled: filled,
          size: size,
          delay: animate ? Duration(milliseconds: 200 * i) : Duration.zero,
          animate: animate,
        );
      }),
    );
  }
}

class _StarIcon extends StatefulWidget {
  const _StarIcon({
    required this.filled,
    required this.size,
    required this.delay,
    required this.animate,
  });

  final bool filled;
  final double size;
  final Duration delay;
  final bool animate;

  @override
  State<_StarIcon> createState() => _StarIconState();
}

class _StarIconState extends State<_StarIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.bounceOut)),
          weight: 40),
    ]).animate(_controller);

    if (widget.animate && widget.filled) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.filled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: widget.size,
      color:
          widget.filled ? AppColors.starGold : AppColors.starEmpty,
    );

    if (!widget.animate || !widget.filled) return icon;

    return ScaleTransition(scale: _scale, child: icon);
  }
}
