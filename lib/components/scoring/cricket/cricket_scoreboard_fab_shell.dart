import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';

/// Bottom-right FAB cluster for overs history and scoring controls.
class CricketScoreboardFabShell extends StatelessWidget {
  const CricketScoreboardFabShell({
    super.key,
    required this.onOpenControls,
    required this.onOpenOvers,
    this.showScoringFab = true,
    this.showOversFab = true,
    this.fabBottomInset = 16,
  });

  final VoidCallback onOpenControls;
  final VoidCallback onOpenOvers;
  final bool showScoringFab;
  final bool showOversFab;

  /// Extra lift for the FAB cluster (e.g. above an innings-complete bar).
  final double fabBottomInset;

  static const double _fabSize = 56;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    if (!showScoringFab && !showOversFab) {
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
          if (showOversFab)
            _ScoreboardFab(
              tooltip: 'Overs',
              backgroundColor: Colors.white,
              foregroundColor: const Color(AppColors.textColor),
              icon: Icons.format_list_numbered_rounded,
              onPressed: onOpenOvers,
            ),
          if (showOversFab && showScoringFab) const SizedBox(height: 12),
          if (showScoringFab)
            _ScoreboardFab(
              tooltip: 'Score',
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              icon: Icons.sports_cricket_rounded,
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
            width: CricketScoreboardFabShell._fabSize,
            height: CricketScoreboardFabShell._fabSize,
            child: Icon(
              icon,
              size: CricketScoreboardFabShell._iconSize,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
