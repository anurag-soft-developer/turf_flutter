import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/constants.dart';

/// Brand app-bar backdrop: primary→secondary gradient + faint arc watermark.
class AppBarBackground extends StatelessWidget {
  const AppBarBackground({super.key});

  static const String watermarkAsset = 'assets/graphics/app_bar_arcs.svg';

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(AppColors.primaryColor),
                Color(AppColors.secondaryColor),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x14FFFFFF),
                Color(0x00FFFFFF),
              ],
            ),
          ),
        ),
        _ArcWatermark(),
      ],
    );
  }
}

class _ArcWatermark extends StatelessWidget {
  const _ArcWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.11,
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 200,
            height: 140,
            child: SvgPicture.asset(
              AppBarBackground.watermarkAsset,
              fit: BoxFit.cover,
              alignment: Alignment.bottomRight,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drop-in [AppBar] with the shared gradient + watermark background.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle,
    this.automaticallyImplyLeading,
    this.toolbarHeight,
    this.titleSpacing,
    this.foregroundColor = Colors.white,
    this.elevation = 0,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final bool? automaticallyImplyLeading;
  final double? toolbarHeight;
  final double? titleSpacing;
  final Color? foregroundColor;
  final double elevation;

  @override
  Size get preferredSize {
    final height = toolbarHeight ?? kToolbarHeight;
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(height + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      toolbarHeight: toolbarHeight,
      titleSpacing: titleSpacing,
      foregroundColor: foregroundColor,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      flexibleSpace: const AppBarBackground(),
    );
  }
}
