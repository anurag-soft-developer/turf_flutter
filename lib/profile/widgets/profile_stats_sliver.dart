import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../components/player/profile/sport_stats_view.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../../core/models/user/user_model.dart';

/// Football / Cricket stats as slivers. Sport tabs are tap-only (no swipe).
class ProfileStatsSliver extends HookWidget {
  const ProfileStatsSliver({
    super.key,
    required this.sports,
    required this.sportTabController,
    required this.statsForSport,
  });

  final List<SportType> sports;
  final TabController sportTabController;
  final PlayerSportEntry? Function(SportType sport) statsForSport;

  @override
  Widget build(BuildContext context) {
    useListenable(sportTabController);

    if (sports.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No sport stats available',
            style: TextStyle(color: Color(AppColors.textSecondaryColor)),
          ),
        ),
      );
    }

    final index = sportTabController.index.clamp(0, sports.length - 1);
    final sport = sports[index];

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: AppSegmentedTabs(
            controller: sportTabController,
            fillWidth: true,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            items: sports
                .map(
                  (item) => item == SportType.football
                      ? const AppTabItem(
                          label: 'Football',
                          icon: Icons.sports_soccer,
                        )
                      : const AppTabItem(
                          label: 'Cricket',
                          icon: Icons.sports_cricket,
                        ),
                )
                .toList(),
          ),
        ),
        SliverToBoxAdapter(
          child: SportStatsView(
            sport: sport,
            stats: statsForSport(sport),
          ),
        ),
      ],
    );
  }
}
