import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/user_avatar_app_bar_action.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/config/constants.dart';
import '../team/model/team_model.dart';

class _ScoreboardSportOption {
  const _ScoreboardSportOption({
    required this.sport,
    required this.enabled,
    this.onTap,
  });

  final TeamSportType sport;
  final bool enabled;
  final VoidCallback? onTap;
}

/// Bottom-tab hub for starting casual scoreboard sessions by sport.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  static List<_ScoreboardSportOption> get _sports => [
        _ScoreboardSportOption(
          sport: TeamSportType.cricket,
          enabled: true,
          onTap: () => _openCasualMatch(TeamSportType.cricket),
        ),
        _ScoreboardSportOption(
          sport: TeamSportType.football,
          enabled: true,
          onTap: () => _openCasualMatch(TeamSportType.football),
        ),
      ];

  static void _openCasualMatch(TeamSportType sport) {
    Get.toNamed(
      AppConstants.routes.matchUpCasual,
      parameters: {'sport': sport.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 20.0;
    const spacing = 12.0;
    const minTileWidth = 140.0;

    final maxWidth =
        MediaQuery.sizeOf(context).width - (horizontalPadding * 2);
    final columns =
        ((maxWidth + spacing) / (minTileWidth + spacing)).floor().clamp(2, 3);
    final tileWidth = (maxWidth - spacing * (columns - 1)) / columns;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const FloatingSliverAppBar(
            leading: UserAvatarAppBarAction(),
            title: Text('Scoreboard'),
          ),
        ],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose a sport',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final option in _sports)
                      SizedBox(
                        width: tileWidth,
                        child: _SportTile(option: option),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({required this.option});

  final _ScoreboardSportOption option;

  @override
  Widget build(BuildContext context) {
    final sport = option.sport;
    final enabled = option.enabled;

    return Material(
      color: const Color(AppColors.surfaceColor),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? option.onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(
                  AppColors.dividerColor,
                ).withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sport.icon,
                    size: 28,
                    color: const Color(AppColors.primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  sport.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
