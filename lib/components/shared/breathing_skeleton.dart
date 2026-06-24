import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

/// Pulses placeholder opacity for loading states.
class BreathingSkeleton extends StatefulWidget {
  const BreathingSkeleton({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1200),
    this.minOpacity = 0.28,
    this.maxOpacity = 0.72,
  });

  final Widget Function(double opacity) builder;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  @override
  State<BreathingSkeleton> createState() => _BreathingSkeletonState();
}

class _BreathingSkeletonState extends State<BreathingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => widget.builder(_opacity.value),
    );
  }
}

class BreathingBlock extends StatelessWidget {
  const BreathingBlock({
    super.key,
    required this.opacity,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.color,
  });

  final double opacity;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (color ?? const Color(AppColors.dividerColor))
            .withValues(alpha: opacity),
        borderRadius: borderRadius,
      ),
    );
  }
}

class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    super.key,
    required this.opacity,
    required this.size,
    this.color,
  });

  final double opacity;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return BreathingBlock(
      opacity: opacity,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      color: color,
    );
  }
}
