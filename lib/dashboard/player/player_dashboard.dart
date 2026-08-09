import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/dashboard/battle_mode_card.dart';
import '../../components/dashboard/dashboard_leaderboard_section.dart';
import '../../components/dashboard/sports_section.dart';
import '../../components/dashboard/team_action_cards.dart';
import '../../components/turf/featured_section.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../settings/settings_controller.dart';
import '../dashboard_service.dart';
import '../model/player_dashboard_model.dart';
import 'player_dashboard_controller.dart';

class PlayerDashboard extends HookWidget {
  const PlayerDashboard({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthStateController>();
    final settings = Get.find<SettingsController>();
    final queryClient = useQueryClient();

    return RefreshIndicator(
      onRefresh: () async {
        await settings.resolveLocation();
        await Future.wait([
          queryClient.invalidateQueries(
            queryKey: QueryKeys.playerDashboardPrefix,
          ),
          queryClient.invalidateQueries(
            queryKey: QueryKeys.dashboardLeaderboard,
          ),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Obx(() {
                final name = authController.user?.fullName?.trim();
                final displayName = (name != null && name.isNotEmpty)
                    ? name.split(' ').first
                    : 'there';

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
            Obx(() {
              final ready = settings.isLocationReady.value;
              final location = settings.nearbyLocation.value;

              if (!ready) {
                return const _PlayerDashboardFeedPlaceholder();
              }

              final locKey = location == null
                  ? 'no-location'
                  : '${location.latitude.toStringAsFixed(4)},'
                      '${location.longitude.toStringAsFixed(4)}';

              return _PlayerDashboardFeed(
                key: ValueKey(locKey),
                location: location,
              );
            }),
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

class _PlayerDashboardFeedPlaceholder extends StatelessWidget {
  const _PlayerDashboardFeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: BattleModeCard(nearbyTeamsCount: 0),
        ),
        SizedBox(height: 28),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Featured turves',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        SizedBox(height: 12),
        FeaturedTurfsSection(turfs: [], isLoading: true),
      ],
    );
  }
}

class _PlayerDashboardFeed extends HookWidget {
  const _PlayerDashboardFeed({super.key, this.location});

  final LocationModel? location;

  @override
  Widget build(BuildContext context) {
    final dashboardQuery = useQuery<PlayerDashboardModel, Object>(
      QueryKeys.playerDashboard(
        lat: location == null
            ? null
            : double.parse(location!.latitude.toStringAsFixed(4)),
        lng: location == null
            ? null
            : double.parse(location!.longitude.toStringAsFixed(4)),
      ),
      (_) async {
        final data = await DashboardService().getPlayerDashboard(
          location: location,
        );
        if (data == null) {
          throw Exception('Failed to load dashboard');
        }
        if (Get.isRegistered<PlayerDashboardController>()) {
          Get.find<PlayerDashboardController>().unreadNotificationCount.value =
              data.unreadNotificationCount;
        }
        return data;
      },
      retry: shortRetry,
      staleDuration: const StaleDuration(minutes: 5),
      gcDuration: const GcDuration(minutes: 30),
    );

    final data = dashboardQuery.data ?? PlayerDashboardModel.empty;
    final isLoading = dashboardQuery.isLoading && data.turfs.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BattleModeCard(nearbyTeamsCount: data.nearbyTeamsCount),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            data.turfsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FeaturedTurfsSection(
          turfs: data.turfs,
          isLoading: isLoading,
          hasError: dashboardQuery.isError && data.turfs.isEmpty,
          onRetry: () => dashboardQuery.refetch(),
        ),
      ],
    );
  }
}
