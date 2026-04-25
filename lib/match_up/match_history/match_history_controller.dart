import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

enum MatchHistoryTab { completed, upcoming }

class MatchHistoryController extends GetxController
    with
        GetSingleTickerProviderStateMixin,
        SegmentedTabCacheController<MatchHistoryTab, TeamMatchModel> {
  final TeamService _teamService = TeamService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final Rx<MatchHistoryTab> selectedHistoryTab = MatchHistoryTab.completed.obs;
  final RxBool isLoadingTeams = true.obs;
  final RxList<TeamMemberModel> myMemberships = <TeamMemberModel>[].obs;
  final Rx<TeamMemberFieldInstance?> selectedTeam =
      Rx<TeamMemberFieldInstance?>(null);

  static const _pageLimit = 20;

  @override
  List<MatchHistoryTab> get tabKeys => MatchHistoryTab.values;

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

  List<TeamMemberFieldInstance> get allTeams {
    final list = <TeamMemberFieldInstance>[];
    for (final m in myMemberships) {
      final t = m.team;
      if (t is TeamMemberFieldInstance) {
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

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    _autoSelectTeam();
    refreshAllTabs();
  }

  void switchHistoryTab(MatchHistoryTab tab) {
    if (selectedHistoryTab.value == tab) return;
    selectedHistoryTab.value = tab;
    ensureTabLoaded(tab);
  }

  void selectTeam(TeamMemberFieldInstance team) {
    if (selectedTeam.value?.id == team.id) return;
    selectedTeam.value = team;
    selectedSport.value = team.sportType;
    refreshAllTabs();
  }

  Future<void> _loadMyTeams() async {
    isLoadingTeams.value = true;
    try {
      final result = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      myMemberships.assignAll(result?.data ?? []);
      _autoSelectTeam();
      refreshAllTabs();
    } finally {
      isLoadingTeams.value = false;
    }
  }

  void _autoSelectTeam() {
    final teams = allTeams;
    if (teams.isEmpty) {
      selectedTeam.value = null;
    } else if (selectedTeam.value == null ||
        !teams.any((t) => t.id == selectedTeam.value!.id)) {
      selectedTeam.value = teams.first;
      selectedSport.value = teams.first.sportType;
    }
  }

  Future<void> refreshAllTabs() async {
    _resetTabCache();
    if (selectedTeam.value?.id == null) return;
    await ensureTabLoaded(selectedHistoryTab.value);
  }

  void _resetTabCache() {
    for (final tab in tabKeys) {
      setTabState(tab, const SegmentedTabDataState<TeamMatchModel>());
    }
  }

  @override
  Future<List<TeamMatchModel>> fetchTabItems(MatchHistoryTab tab) async {
    final teamId = selectedTeam.value?.id;
    if (teamId == null) return <TeamMatchModel>[];

    switch (tab) {
      case MatchHistoryTab.completed:
        final result = await _matchmakingService.listRequests(
          ListNegotiationsFilterQuery(
            teamId: teamId,
            type: NegotiationListType.all,
            status: TeamMatchStatus.completed,
            page: 1,
            limit: _pageLimit,
          ),
        );

        final drawResult = await _matchmakingService.listRequests(
          ListNegotiationsFilterQuery(
            teamId: teamId,
            type: NegotiationListType.all,
            status: TeamMatchStatus.draw,
            page: 1,
            limit: _pageLimit,
          ),
        );

        final List<TeamMatchModel> matches = [
          ...(result?.data ?? []),
          ...(drawResult?.data ?? []),
        ];
        matches.sort(
          (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
            a.updatedAt ?? a.createdAt ?? DateTime(2000),
          ),
        );

        return matches;
      case MatchHistoryTab.upcoming:
        final scheduled = await _matchmakingService.listRequests(
          ListNegotiationsFilterQuery(
            teamId: teamId,
            type: NegotiationListType.all,
            status: TeamMatchStatus.scheduleFinalized,
            page: 1,
            limit: _pageLimit,
          ),
        );

        final negotiating = await _matchmakingService.listRequests(
          ListNegotiationsFilterQuery(
            teamId: teamId,
            type: NegotiationListType.all,
            status: TeamMatchStatus.accepted,
            page: 1,
            limit: _pageLimit,
          ),
        );

        final List<TeamMatchModel> matches = [
          ...(scheduled?.data ?? []),
          ...(negotiating?.data ?? []),
        ];
        matches.sort(
          (a, b) => (a.createdAt ?? DateTime(2099)).compareTo(
            b.createdAt ?? DateTime(2099),
          ),
        );

        return matches;
    }
  }

  Future<void> refreshTab(MatchHistoryTab tab) async {
    setTabState(tab, const SegmentedTabDataState<TeamMatchModel>());
    await ensureTabLoaded(tab, force: true);
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load matches';
  }

  Future<void> reload() async {
    await _loadMyTeams();
  }
}
