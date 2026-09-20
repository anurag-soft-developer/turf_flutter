import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

/// Bottom-right FAB cluster shared by cricket and football scoreboards.
class ScoreboardFabShell extends StatelessWidget {
  const ScoreboardFabShell({
    super.key,
    required this.onOpenControls,
    required this.onOpenSecondary,
    required this.secondaryTooltip,
    this.showControlsFab = true,
    this.showSecondaryFab = true,
    this.fabBottomInset = 16,
  });

  final VoidCallback onOpenControls;
  final VoidCallback onOpenSecondary;
  final String secondaryTooltip;
  final bool showControlsFab;
  final bool showSecondaryFab;
  final double fabBottomInset;

  static const double _fabSize = 56;
  static const double _iconSize = 24;

  static const IconData controlsIcon = Icons.sports_score_rounded;
  static const IconData secondaryIcon = Icons.format_list_bulleted_rounded;

  @override
  Widget build(BuildContext context) {
    if (!showControlsFab && !showSecondaryFab) {
      return const SizedBox.shrink();
    }

    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      right: 16,
      bottom: fabBottomInset + bottomPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showSecondaryFab)
            _ScoreboardFab(
              tooltip: secondaryTooltip,
              backgroundColor: Colors.white,
              foregroundColor: const Color(AppColors.textColor),
              icon: secondaryIcon,
              onPressed: onOpenSecondary,
            ),
          if (showSecondaryFab && showControlsFab) const SizedBox(height: 12),
          if (showControlsFab)
            _ScoreboardFab(
              tooltip: 'Score',
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              icon: controlsIcon,
              onPressed: onOpenControls,
            ),
        ],
      ),
    );
  }
}

class _ScoreboardFab extends StatelessWidget {
  const _ScoreboardFab({
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        elevation: 3,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: ScoreboardFabShell._fabSize,
            height: ScoreboardFabShell._fabSize,
            child: Icon(
              icon,
              size: ScoreboardFabShell._iconSize,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
