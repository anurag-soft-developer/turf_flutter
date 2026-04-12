import 'package:get/get.dart';

import '../../core/utils/app_snackbar.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

/// Lists match requests; filter by one team or merge all of the user’s teams.
class MatchChallengesController extends GetxController {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TeamService _teamService = TeamService();

  final RxInt tabIndex = 0.obs;
  final RxList<TeamMatchModel> received = <TeamMatchModel>[].obs;
  final RxList<TeamMatchModel> sent = <TeamMatchModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMemberships = true.obs;
  final Rxn<String> acceptingMatchId = Rxn<String>();

  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;
  final RxBool filterAllTeams = true.obs;
  final Rxn<TeamMemberFieldInstance> selectedMembershipTeam =
      Rxn<TeamMemberFieldInstance>();

  bool get isReceivedTab => tabIndex.value == 0;

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
    await loadCurrentTab();
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
    loadCurrentTab();
  }

  void selectAllTeamsFilter() {
    filterAllTeams.value = true;
    loadCurrentTab();
  }

  Future<void> loadCurrentTab() async {
    if (myTeams.isEmpty) {
      received.clear();
      sent.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final type = isReceivedTab
          ? NegotiationListType.incoming
          : NegotiationListType.outgoing;
      if (filterAllTeams.value) {
        await _loadMerged(type);
      } else {
        final tid = selectedMembershipTeam.value?.id;
        if (tid == null || tid.isEmpty) {
          received.clear();
          sent.clear();
          return;
        }
        final res = await _matchmakingService.listRequests(
          ListNegotiationsFilterQuery(teamId: tid, type: type, limit: 50),
        );
        final items = res?.data ?? [];
        if (isReceivedTab) {
          received.assignAll(items);
        } else {
          sent.assignAll(items);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMerged(NegotiationListType type) async {
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
    final list = merged.values.toList()
      ..sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    if (isReceivedTab) {
      received.assignAll(list);
    } else {
      sent.assignAll(list);
    }
  }

  Future<void> switchTab(int index) async {
    if (tabIndex.value == index) return;
    tabIndex.value = index;
    await loadCurrentTab();
  }

  Future<void> refreshAll() async {
    await loadMemberships();
    await loadCurrentTab();
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
        received.removeWhere((m) => m.id == matchId);
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
