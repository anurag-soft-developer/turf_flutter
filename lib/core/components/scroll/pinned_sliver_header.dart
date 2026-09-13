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
    this.showBottomBorder = false,
  });

  /// Soft white filter strip under a branded gradient app bar.
  const PinnedSliverHeader.surfaceCard({
    super.key,
    required this.child,
  })  : backgroundColor = const Color(AppColors.surfaceColor),
        elevation = 0,
        showBottomBorder = true;

  final Widget child;
  final Color backgroundColor;
  final double elevation;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: Material(
        color: backgroundColor,
        elevation: elevation,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: const Color(AppColors.dividerColor)
                          .withValues(alpha: 0.7),
                    ),
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
