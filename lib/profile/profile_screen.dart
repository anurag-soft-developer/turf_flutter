import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../components/player/profile/player_badges_section.dart';
import '../components/player/profile/player_hero_section.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/components/query/query_async_body.dart';
import '../core/config/constants.dart';
import '../core/models/user/user_model.dart';
import '../core/models/user_field_instance.dart';
import '../core/query/query_keys.dart';
import '../core/query/query_retry.dart';
import '../core/services/auth_service.dart';
import 'widgets/profile_posts_grid.dart';
import 'widgets/profile_scroll_scaffold.dart';
import 'widgets/profile_stats_sliver.dart';

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
    final queryClient = useQueryClient();

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

    final outerTabController = useTabController(initialLength: 2);
    final sportTabController = useTabController(
      initialLength: availableSports.length,
      keys: [availableSports.length],
    );

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
            onPressed: () => Get.toNamed(AppConstants.routes.createPost),
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'New post',
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
          final userId = resolved.id ?? authController.user?.id ?? '';

          Future<void> onRefresh() async {
            await Future.wait([
              profileQuery.refetch(),
              if (userId.isNotEmpty)
                queryClient.invalidateQueries(
                  queryKey: QueryKeys.userPosts(userId),
                ),
            ]);
          }

          return ProfileScrollScaffold(
            onRefresh: onRefresh,
            hero: PlayerHeroSection(helper: helper),
            badges: PlayerBadgesSection(
              badges: helper.getModel()?.badges ?? [],
            ),
            outerTabController: outerTabController,
            photosSliver: userId.isEmpty
                ? const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: Center(child: Text('No photos yet')),
                    ),
                  )
                : ProfilePostsGrid(userId: userId),
            statsSliver: ProfileStatsSliver(
              sports: sports,
              sportTabController: sportTabController,
              statsForSport: (sport) => _statsForSport(resolved, sport),
            ),
          );
        },
      ),
    );
  }
}
