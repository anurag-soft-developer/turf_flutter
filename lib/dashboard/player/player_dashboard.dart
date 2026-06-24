import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/dashboard/battle_mode_card.dart';
import '../../components/dashboard/dashboard_leaderboard_section.dart';
import '../../components/dashboard/sports_section.dart';
import '../../components/dashboard/team_action_cards.dart';
import '../../components/turf/featured_section.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../dashboard/player/dashboard_leaderboard_controller.dart';
import '../../turf/feed/turf_list_controller.dart';

class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  Future<void> _onRefresh() async {
    await Future.wait([
      Get.find<TurfListController>().loadFeaturedTurfs(),
      Get.find<DashboardLeaderboardController>().loadLeaderboard(),
    ]);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthStateController>();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Obx(() {
                final name = authController.user?.fullName?.trim();
                final displayName =
                    (name != null && name.isNotEmpty) ? name.split(' ').first : 'there';

                return Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.3,
                      color: Color(AppColors.textColor),
                    ),
                    children: [
                      TextSpan(
                        text: '${_greeting()}, ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: BattleModeCard(),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Nearby turfs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const FeaturedTurfsSection(),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: SportsSection(),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: DashboardLeaderboardSection(),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: TeamActionCardsRow(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
