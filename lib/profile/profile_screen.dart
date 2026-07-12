import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../components/player/profile/player_badges_section.dart';
import '../components/player/profile/player_hero_section.dart';
import '../components/player/profile/sport_stats_view.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/components/query/query_async_body.dart';
import '../core/config/constants.dart';
import '../core/models/user/user_model.dart';
import '../core/models/user_field_instance.dart';
import '../core/query/query_keys.dart';
import '../core/query/query_retry.dart';
import '../core/services/auth_service.dart';

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  List<SportType> _availableSports(UserModel? user) {
    if (user == null || user.playerSportStats.isEmpty) {
      return [SportType.football, SportType.cricket];
    }
    return user.playerSportStats
        .map((entry) {
          return entry.sportType == 'cricket'
              ? SportType.cricket
              : SportType.football;
        })
        .toSet()
        .toList();
  }

  PlayerSportEntry? _statsForSport(UserModel? user, SportType sport) {
    if (user == null || user.playerSportStats.isEmpty) return null;
    final sportStr = sport == SportType.cricket ? 'cricket' : 'football';
    try {
      return user.playerSportStats.firstWhere(
        (entry) => entry.sportType == sportStr,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthStateController>();
    final ticker = useSingleTickerProvider();

    final profileQuery = useQuery<UserModel, Object>(
      QueryKeys.profile,
      (_) async {
        final profile = await AuthService().getCurrentUserProfile();
        if (profile != null) {
          authController.applyUserProfile(profile);
          return profile;
        }
        final cached = authController.user;
        if (cached != null) return cached;
        throw Exception('Failed to load profile');
      },
      retry: noRetry,
      seed: authController.user,
    );

    final availableSports = _availableSports(
      profileQuery.data ?? authController.user,
    );

    final tabController = useMemoized(
      () => TabController(length: availableSports.length, vsync: ticker),
      [availableSports.length, ticker],
    );

    useEffect(() {
      return tabController.dispose;
    }, [tabController]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const UserAvatarAppBarAction(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: profileQuery.isFetching
                ? null
                : () => profileQuery.refetch(),
            icon: profileQuery.isFetching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppConstants.routes.editProfile),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: QueryAsyncBody<UserModel, Object>(
        state: profileQuery,
        onRetry: () => profileQuery.refetch(),
        data: (resolved) {
          final helper = UserFieldInstance(resolved);
          final sports = _availableSports(resolved);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: PlayerHeroSection(helper: helper)),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      PlayerBadgesSection(
                        badges: helper.getModel()?.badges ?? [],
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                const SizedBox(height: 24),
                if (sports.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: tabController,
                      labelColor: const Color(AppColors.primaryColor),
                      unselectedLabelColor: const Color(
                        AppColors.textSecondaryColor,
                      ),
                      indicatorColor: const Color(AppColors.primaryColor),
                      tabs: sports.map((sport) {
                        if (sport == SportType.football) {
                          return const Tab(
                            icon: Icon(Icons.sports_soccer, size: 20),
                            text: 'Football',
                          );
                        }
                        return const Tab(
                          icon: Icon(Icons.sports_cricket, size: 20),
                          text: 'Cricket',
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: sports.map((sport) {
                        final stats = _statsForSport(resolved, sport);
                        return SportStatsView(sport: sport, stats: stats);
                      }).toList(),
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No sport stats available',
                        style: TextStyle(
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
