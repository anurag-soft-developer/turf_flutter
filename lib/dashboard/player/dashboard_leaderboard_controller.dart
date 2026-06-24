import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/models/user/player_stats_models.dart';
import '../../core/services/user_service.dart';
import '../../rankings/model/player_leaderboard_model.dart';

class DashboardLeaderboardController extends GetxController {
  final UserService _userService = UserService();
  final AuthStateController _auth = Get.find<AuthStateController>();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<PlayerLeaderboardRow> topThree = <PlayerLeaderboardRow>[].obs;
  final Rxn<PlayerLeaderboardRow> currentUserRow = Rxn<PlayerLeaderboardRow>();

  SportType get sport => SportType.cricket;

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _userService.getLeaderboard(
        PlayerLeaderboardQuery(sportType: sport, page: 1, limit: 50),
      );
      final items = result?.data ?? <PlayerLeaderboardRow>[];

      topThree.assignAll(
        items.where((e) => e.rank >= 1 && e.rank <= 3).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank)),
      );

      final userId = _auth.user?.id;
      PlayerLeaderboardRow? me;
      if (userId != null && userId.isNotEmpty) {
        for (final row in items) {
          if (row.id == userId) {
            me = row;
            break;
          }
        }
      }
      me ??= _buildCurrentUserFallback();

      final isInTopThree = me.rank >= 1 && me.rank <= 3;
      currentUserRow.value = isInTopThree ? null : me;
    } catch (_) {
      error.value = 'Failed to load leaderboard';
      topThree.clear();
      final fallback = _buildCurrentUserFallback();
      currentUserRow.value =
          fallback.rank >= 1 && fallback.rank <= 3 ? null : fallback;
    } finally {
      isLoading.value = false;
    }
  }

  PlayerLeaderboardRow _buildCurrentUserFallback() {
    final user = _auth.user;
    final points = user?.sportRankingPoints
            .where((e) => e.sportType == sport.name)
            .map((e) => e.points)
            .firstOrNull ??
        0;

    return PlayerLeaderboardRow(
      rank: 0,
      id: user?.id ?? '',
      name: user?.displayName ?? 'You',
      points: points,
      avatar: user?.avatar,
    );
  }

  PlayerLeaderboardRow? entryForRank(int rank) {
    for (final entry in topThree) {
      if (entry.rank == rank) return entry;
    }
    return null;
  }
}
