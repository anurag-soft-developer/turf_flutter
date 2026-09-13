import 'package:flutter/material.dart';

import '../app_bar/app_bar_background.dart';

/// Shared floating+snap app bar for tabs and list screens.
class FloatingSliverAppBar extends StatelessWidget {
  const FloatingSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.foregroundColor = Colors.white,
    this.centerTitle,
    this.automaticallyImplyLeading,
    this.toolbarHeight,
    this.titleSpacing,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color foregroundColor;
  final bool? centerTitle;
  final bool? automaticallyImplyLeading;
  final double? toolbarHeight;
  final double? titleSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: automaticallyImplyLeading ?? (leading == null),
      leading: leading,
      title: title,
      actions: actions,
      foregroundColor: foregroundColor,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight ?? kToolbarHeight,
      titleSpacing: titleSpacing,
      elevation: 0,
      scrolledUnderElevation: 0,
      forceElevated: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: const AppBarBackground(),
    );
  }
}

/// Pull-to-refresh offset so the indicator clears the floating app bar + status bar.
double floatingRefreshEdgeOffset(
  BuildContext context, {
  double toolbarHeight = kToolbarHeight,
}) {
  return MediaQuery.paddingOf(context).top + toolbarHeight;
}
