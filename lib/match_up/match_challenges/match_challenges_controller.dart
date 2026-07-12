import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/members/model/team_member_model.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

enum MatchChallengesTab { received, sent, live, upcoming, completed, archive }

/// UI + accept/reject mutations. List fetching is owned by flutter_query on the screen.
class MatchChallengesController extends GetxController {
  final MatchmakingService _matchmakingService = MatchmakingService();

  final Rx<MatchChallengesTab> selectedTab = MatchChallengesTab.received.obs;
  final Rxn<String> acceptingMatchId = Rxn<String>();
  final Rxn<String> rejectingMatchId = Rxn<String>();

  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;
  final RxBool filterAllTeams = true.obs;
  final Rxn<TeamMemberFieldInstance> selectedMembershipTeam =
      Rxn<TeamMemberFieldInstance>();

  List<TeamMemberFieldInstance> get myTeams {
    final list = <TeamMemberFieldInstance>[];
    for (final m in memberships) {
      final t = m.team;
      if (t is TeamMemberFieldInstance && t.id != null && t.id!.isNotEmpty) {
        list.add(t);
      }
    }
    final seen = <String>{};
    return list.where((t) => seen.add(t.id!)).toList();
  }

  /// Team filter key segment for [QueryKeys.matchChallenges].
  String get teamFilterKey {
    if (filterAllTeams.value) return 'all';
    return selectedMembershipTeam.value?.id ?? 'all';
  }

  /// Team ids for list endpoints: one selected team or all distinct [myTeams] ids.
  List<String> activeTeamIdsForList() {
    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) return <String>[];
      return <String>[tid];
    }
    final ids = <String>[];
    final seen = <String>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      if (seen.add(tid)) ids.add(tid);
    }
    return ids;
  }

  void syncMemberships(List<TeamMemberModel> data) {
    memberships.assignAll(data);
    if (!filterAllTeams.value) {
      final sel = selectedMembershipTeam.value;
      if (sel != null && !myTeams.any((t) => t.id == sel.id)) {
        selectedMembershipTeam.value = myTeams.isNotEmpty
            ? myTeams.first
            : null;
      }
    }
  }

  void selectTeamForFilter(TeamMemberFieldInstance team) {
    filterAllTeams.value = false;
    selectedMembershipTeam.value = team;
  }

  void selectAllTeamsFilter() {
    filterAllTeams.value = true;
  }

  void switchTab(int index) {
    if (index < 0 || index >= MatchChallengesTab.values.length) return;
    final tab = MatchChallengesTab.values[index];
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
  }

  Future<void> invalidateChallengeQueries() async {
    if (!Get.isRegistered<QueryClient>()) return;
    await Get.find<QueryClient>().invalidateQueries(
      queryKey: const ['matchChallenges'],
    );
  }

  Future<void> acceptChallenge(TeamMatchModel match) async {
    final matchId = match.id;
    final actorId = match.toTeamHelper.getId();
    if (matchId == null ||
        matchId.isEmpty ||
        actorId == null ||
        actorId.isEmpty) {
      return;
    }
    if (match.status != TeamMatchStatus.requested) return;
    if (_isMatchExpiredByDeadline(match)) return;

    acceptingMatchId.value = matchId;
    try {
      final updated = await _matchmakingService.respond(
        matchId,
        RespondMatchRequest(
          actorTeamId: actorId,
          action: MatchResponseAction.accept,
        ),
      );
      if (updated != null) {
        AppSnackbar.success(
          title: 'Challenge accepted',
          message:
              'You can continue scheduling from match details when available.',
        );
        await invalidateChallengeQueries();
      } else {
        AppSnackbar.error(
          title: 'Could not accept',
          message: 'Try again later.',
        );
      }
    } finally {
      acceptingMatchId.value = null;
    }
  }

  Future<void> rejectChallenge(TeamMatchModel match) async {
    final matchId = match.id;
    final actorId = match.toTeamHelper.getId();
    if (matchId == null ||
        matchId.isEmpty ||
        actorId == null ||
        actorId.isEmpty) {
      return;
    }
    if (match.status != TeamMatchStatus.requested) return;
    if (_isMatchExpiredByDeadline(match)) return;

    rejectingMatchId.value = matchId;
    try {
      final updated = await _matchmakingService.respond(
        matchId,
        RespondMatchRequest(
          actorTeamId: actorId,
          action: MatchResponseAction.reject,
        ),
      );
      if (updated != null) {
        AppSnackbar.success(
          title: 'Challenge rejected',
          message: 'The match request was declined.',
        );
        await invalidateChallengeQueries();
      } else {
        AppSnackbar.error(
          title: 'Could not reject',
          message: 'Try again later.',
        );
      }
    } finally {
      rejectingMatchId.value = null;
    }
  }

  static bool _isMatchExpiredByDeadline(TeamMatchModel m) {
    final ex = m.expiresAt;
    if (ex == null) return false;
    return DateTime.now().isAfter(ex.toLocal());
  }
}
