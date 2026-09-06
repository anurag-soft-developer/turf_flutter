import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../config/constants.dart';

/// Content-sized pinned header for filter/tab rows under a floating [SliverAppBar].
///
/// Uses [SliverPinnedHeader] so height follows the child (no fixed extent).
class PinnedSliverHeader extends StatelessWidget {
  const PinnedSliverHeader({
    super.key,
    required this.child,
    this.backgroundColor = const Color(AppColors.backgroundColor),
    this.elevation = 0,
  });

  final Widget child;
  final Color backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: Material(
        color: backgroundColor,
        elevation: elevation,
        child: child,
      ),
    );
  }
}
