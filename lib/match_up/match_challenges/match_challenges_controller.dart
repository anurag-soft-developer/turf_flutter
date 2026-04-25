import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

enum MatchChallengesTab { received, sent }

/// Lists match requests; filter by one team or merge all of the user’s teams.
class MatchChallengesController extends GetxController
    with SegmentedTabCacheController<MatchChallengesTab, TeamMatchModel> {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TeamService _teamService = TeamService();

  final Rx<MatchChallengesTab> selectedTab = MatchChallengesTab.received.obs;
  final RxBool isLoadingMemberships = true.obs;
  final Rxn<String> acceptingMatchId = Rxn<String>();

  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;
  final RxBool filterAllTeams = true.obs;
  final Rxn<TeamMemberFieldInstance> selectedMembershipTeam =
      Rxn<TeamMemberFieldInstance>();

  @override
  List<MatchChallengesTab> get tabKeys => MatchChallengesTab.values;

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

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await loadMemberships();
    await loadSelectedTab();
  }

  Future<void> loadMemberships() async {
    isLoadingMemberships.value = true;
    try {
      final res = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      memberships.assignAll(res?.data ?? []);
      if (!filterAllTeams.value) {
        final sel = selectedMembershipTeam.value;
        if (sel != null && !myTeams.any((t) => t.id == sel.id)) {
          selectedMembershipTeam.value = myTeams.isNotEmpty
              ? myTeams.first
              : null;
        }
      }
    } finally {
      isLoadingMemberships.value = false;
    }
  }

  void selectTeamForFilter(TeamMemberFieldInstance team) {
    filterAllTeams.value = false;
    selectedMembershipTeam.value = team;
    refreshAllTabs();
  }

  void selectAllTeamsFilter() {
    filterAllTeams.value = true;
    refreshAllTabs();
  }

  Future<void> loadSelectedTab() async {
    if (myTeams.isEmpty) {
      _clearAllTabStates();
      return;
    }
    await ensureTabLoaded(selectedTab.value);
  }

  void _clearAllTabStates() {
    for (final tab in tabKeys) {
      setTabState(tab, const SegmentedTabDataState<TeamMatchModel>());
    }
  }

  @override
  Future<List<TeamMatchModel>> fetchTabItems(MatchChallengesTab tab) async {
    final type = tab == MatchChallengesTab.received
        ? NegotiationListType.incoming
        : NegotiationListType.outgoing;

    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) {
        return <TeamMatchModel>[];
      }
      final res = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(teamId: tid, type: type, limit: 50),
      );
      final items = (res?.data ?? []).toList()
        ..sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      return items;
    }

    final merged = <String, TeamMatchModel>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      final res = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(teamId: tid, type: type, limit: 50),
      );
      for (final m in res?.data ?? []) {
        final mid = m.id;
        if (mid != null && mid.isNotEmpty) merged[mid] = m;
      }
    }
    return merged.values.toList()
      ..sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
  }

  @override
  String mapFetchError(Object error) => 'Failed to load challenges';

  Future<void> switchTab(int index) async {
    if (index < 0 || index >= MatchChallengesTab.values.length) return;
    final tab = MatchChallengesTab.values[index];
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    await ensureTabLoaded(tab);
  }

  Future<void> refreshCurrentTab() async {
    await ensureTabLoaded(selectedTab.value, force: true);
  }

  Future<void> refreshAllTabs() async {
    _clearAllTabStates();
    await loadSelectedTab();
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
        final receivedState = tabStateFor(MatchChallengesTab.received);
        setTabState(
          MatchChallengesTab.received,
          receivedState.copyWith(
            items: receivedState.items.where((m) => m.id != matchId).toList(),
          ),
        );
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
}
