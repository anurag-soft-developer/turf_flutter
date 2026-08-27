import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/player/profile/player_badges_section.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/player/profile/player_hero_section.dart';
import '../../core/components/query/query_async_body.dart';
import '../../core/config/constants.dart';
import '../../core/models/user/user_model.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/services/user_service.dart';
import '../../profile/widgets/profile_posts_grid.dart';
import '../../profile/widgets/profile_scroll_scaffold.dart';
import '../../profile/widgets/profile_stats_sliver.dart';

/// Route arguments: `{'userId': String}` — public profile user id.
class PlayerProfileScreen extends HookWidget {
  const PlayerProfileScreen({super.key});

  String? _parseUserId(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map) {
      final id = raw['userId'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

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

  PlayerSportEntry? _statsForSport(UserModel user, SportType sport) {
    if (user.playerSportStats.isEmpty) return null;
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
    final userId = useMemoized(() => _parseUserId(Get.arguments));
    final queryClient = useQueryClient();

    if (userId == null || userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: const Center(child: Text('Player not found')),
      );
    }

    final profileQuery = useQuery<UserModel, Object>(
      QueryKeys.publicProfile(userId),
      (_) async {
        final user = await UserService().getPublicProfile(userId);
        if (user == null) throw Exception('Player not found');
        return user;
      },
      retry: noRetry,
    );

    final availableSports = _availableSports(profileQuery.data);

    final outerTabController = useTabController(initialLength: 2);
    final sportTabController = useTabController(
      initialLength: availableSports.length,
      keys: [availableSports.length],
    );

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Player Profile'),
      ),
      body: QueryAsyncBody<UserModel, Object>(
        state: profileQuery,
        onRetry: () => profileQuery.refetch(),
        data: (resolved) {
          final helper = UserFieldInstance(resolved);
          final sports = _availableSports(resolved);

          Future<void> onRefresh() async {
            await Future.wait([
              profileQuery.refetch(),
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
            photosSliver: ProfilePostsGrid(userId: userId),
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
