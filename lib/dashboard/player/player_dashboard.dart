import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/turf/featured_section.dart';
import '../../components/dashboard/player_teams_section.dart';
import '../../components/dashboard/sports_section.dart';
import '../../turf/feed/turf_list_controller.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  Future<void> _onRefresh() =>
      Get.find<TurfListController>().loadFeaturedTurfs();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Turfs Section
            FeaturedTurfsSection(),
            const SizedBox(height: 16),

            // Sports Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SportsSection(),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: PlayerTeamsSection(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
