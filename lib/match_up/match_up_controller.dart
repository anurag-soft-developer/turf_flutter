import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../team/members/model/team_member_model.dart';
import '../team/model/team_model.dart';
import '../team/team_service.dart';
import 'matchmaking_service.dart';
import 'model/team_match_model.dart';

class MatchUpController extends GetxController
    with SegmentedTabCacheController<TeamSportType, TeamModel> {
  static const int _pageSize = 10;

  final TeamService _teamService = TeamService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  final TextEditingController searchController = TextEditingController();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final RxBool isLoadingMyTeams = true.obs;
  final RxBool isSearching = false.obs;
  final RxBool isSendingRequest = false.obs;
  final RxList<TeamMemberModel> myMemberships = <TeamMemberModel>[].obs;
  final Rx<TeamMemberFieldInstance?> selectedTeam =
      Rx<TeamMemberFieldInstance?>(null);

  /// Opponent team ids challenged by the current [selectedTeam] (immediate UI).
  final RxMap<String, Set<String>> challengedOpponentsByFromTeam =
      <String, Set<String>>{}.obs;

  @override
  List<TeamSportType> get tabKeys => TeamSportType.values;

  @override
  bool get paginatedTabs => true;

  /// All user teams that match the currently selected sport.
  List<TeamMemberFieldInstance> get myTeamsForSport {
    final list = <TeamMemberFieldInstance>[];
    for (final m in myMemberships) {
      final t = m.team;
      if (t is TeamMemberFieldInstance && t.sportType == selectedSport.value) {
        list.add(t);
      }
    }
    return list;
  }

  bool get hasTeamForSport => myTeamsForSport.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadMyTeams();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  String? get _searchQuery {
    final text = searchController.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> searchTeams() async {
    isSearching.value = true;
    try {
      await ensureTabLoaded(selectedSport.value, force: true);
    } finally {
      isSearching.value = false;
    }
  }

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    _autoSelectTeam();
    ensureTabLoaded(sport);
  }

  void selectTeam(TeamMemberFieldInstance team) {
    if (selectedTeam.value?.id == team.id) return;
    selectedTeam.value = team;
    ensureTabLoaded(selectedSport.value, force: true);
  }

  bool isTeamChallenged(String? opponentTeamId) {
    final fromTeamId = selectedTeam.value?.id;
    if (fromTeamId == null ||
        opponentTeamId == null ||
        opponentTeamId.isEmpty) {
      return false;
    }
    return challengedOpponentsByFromTeam[fromTeamId]?.contains(
          opponentTeamId,
        ) ??
        false;
  }

  void _markTeamChallenged(String fromTeamId, String opponentTeamId) {
    final existing = challengedOpponentsByFromTeam[fromTeamId] ?? <String>{};
    challengedOpponentsByFromTeam[fromTeamId] = {...existing, opponentTeamId};
  }

  Future<void> _loadMyTeams() async {
    isLoadingMyTeams.value = true;
    try {
      final result = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      myMemberships.assignAll(result?.data ?? []);
      _autoSelectTeam();
      ensureSportFeedLoaded(selectedSport.value);
    } finally {
      isLoadingMyTeams.value = false;
    }
  }

  void _autoSelectTeam() {
    final teams = myTeamsForSport;
    if (teams.isEmpty) {
      selectedTeam.value = null;
    } else if (selectedTeam.value == null ||
        !teams.any((t) => t.id == selectedTeam.value!.id)) {
      selectedTeam.value = teams.first;
    }
  }

  SegmentedTabDataState<TeamModel> feedStateForSport(TeamSportType sport) {
    return tabStateFor(sport);
  }

  Future<void> ensureSportFeedLoaded(TeamSportType sport) async {
    await ensureTabLoaded(sport);
  }

  @override
  Future<List<TeamModel>> fetchTabItems(TeamSportType sport) async {
    return (await fetchTabPage(sport, 1)).items;
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load teams';
  }

  Future<void> reload() async {
    await _loadMyTeams();
  }

  Future<void> reloadSport(TeamSportType sport) async {
    await ensureTabLoaded(sport, force: true);
  }

  Future<void> loadMoreSport(TeamSportType sport) => loadMoreTab(sport);

  @override
  Future<SegmentedTabPageResult<TeamModel>> fetchTabPage(
    TeamSportType sport,
    int page,
  ) async {
    final fromTeamId = selectedTeam.value?.id;
    final result = await _teamService.findMany(
      TeamFilterQuery(
        sportType: sport,
        teamOpenForMatch: true,
        status: TeamStatus.active,
        visibility: TeamVisibility.public,
        page: page,
        limit: _pageSize,
        skipTeamsWithSentRequest: fromTeamId != null,
        fromTeamId: fromTeamId,
        search: _searchQuery,
      ),
    );
    final selectedTeamId = selectedTeam.value?.id;
    final items = (result?.data ?? const <TeamModel>[])
        .where((team) => team.id != null && team.id != selectedTeamId)
        .toList();

    return SegmentedTabPageResult(
      items: items,
      page: result?.page ?? page,
      hasMore: result?.hasNextPage ?? false,
    );
  }

  Future<void> sendChallenge(TeamModel opponent) async {
    final myTeam = selectedTeam.value;
    if (myTeam?.id == null || opponent.id == null) return;

    isSendingRequest.value = true;
    try {
      final match = await _matchmakingService.sendRequest(
        SendMatchRequest(fromTeamId: myTeam!.id!, toTeamId: opponent.id!),
      );
      if (match != null) {
        _markTeamChallenged(myTeam.id!, opponent.id!);
        Get.snackbar(
          'Challenge Sent!',
          'Match request sent to ${opponent.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
        // ensureTabLoaded(selectedSport.value, force: true);
      }
    } catch (e) {
      Get.snackbar(
        'Failed',
        'Could not send match request. Try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      isSendingRequest.value = false;
    }
  }
}
