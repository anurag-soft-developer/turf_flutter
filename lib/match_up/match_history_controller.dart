import 'package:get/get.dart';

import '../core/models/team/team_member_field_instance.dart';
import '../team/members/model/team_member_model.dart';
import '../team/model/team_model.dart';
import '../team/team_service.dart';
import 'matchmaking_service.dart';
import 'model/team_match_model.dart';

class MatchHistoryController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final TeamService _teamService = TeamService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final RxBool isLoadingTeams = true.obs;
  final RxBool isLoadingMatches = false.obs;
  final RxList<TeamMemberModel> myMemberships = <TeamMemberModel>[].obs;
  final Rx<TeamMemberFieldInstance?> selectedTeam =
      Rx<TeamMemberFieldInstance?>(null);

  final RxList<TeamMatchModel> completedMatches = <TeamMatchModel>[].obs;
  final RxList<TeamMatchModel> upcomingMatches = <TeamMatchModel>[].obs;

  final RxInt historyPage = 1.obs;
  final RxInt upcomingPage = 1.obs;
  final RxBool hasMoreHistory = true.obs;
  final RxBool hasMoreUpcoming = true.obs;

  static const _pageLimit = 20;

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
    _refreshMatches();
  }

  void selectTeam(TeamMemberFieldInstance team) {
    if (selectedTeam.value?.id == team.id) return;
    selectedTeam.value = team;
    selectedSport.value = team.sportType;
    _refreshMatches();
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
      _refreshMatches();
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

  Future<void> _refreshMatches() async {
    historyPage.value = 1;
    upcomingPage.value = 1;
    hasMoreHistory.value = true;
    hasMoreUpcoming.value = true;
    completedMatches.clear();
    upcomingMatches.clear();
    if (selectedTeam.value?.id == null) return;
    await Future.wait([_loadHistory(), _loadUpcoming()]);
  }

  Future<void> _loadHistory() async {
    final teamId = selectedTeam.value?.id;
    if (teamId == null) return;

    isLoadingMatches.value = true;
    try {
      final result = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(
          teamId: teamId,
          type: NegotiationListType.all,
          status: TeamMatchStatus.completed,
          page: historyPage.value,
          limit: _pageLimit,
        ),
      );

      final drawResult = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(
          teamId: teamId,
          type: NegotiationListType.all,
          status: TeamMatchStatus.draw,
          page: historyPage.value,
          limit: _pageLimit,
        ),
      );

      final List<TeamMatchModel> matches = [...(result?.data ?? []), ...(drawResult?.data ?? [])];
      matches.sort(
          (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
                a.updatedAt ?? a.createdAt ?? DateTime(2000),
              ));

      if (historyPage.value == 1) {
        completedMatches.assignAll(matches);
      } else {
        completedMatches.addAll(matches);
      }
      hasMoreHistory.value =
          (result?.hasNextPage ?? false) || (drawResult?.hasNextPage ?? false);
    } finally {
      isLoadingMatches.value = false;
    }
  }

  Future<void> _loadUpcoming() async {
    final teamId = selectedTeam.value?.id;
    if (teamId == null) return;

    isLoadingMatches.value = true;
    try {
      final scheduled = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(
          teamId: teamId,
          type: NegotiationListType.all,
          status: TeamMatchStatus.scheduleFinalized,
          page: upcomingPage.value,
          limit: _pageLimit,
        ),
      );

      final negotiating = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(
          teamId: teamId,
          type: NegotiationListType.all,
          status: TeamMatchStatus.accepted,
          page: upcomingPage.value,
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
              ));

      if (upcomingPage.value == 1) {
        upcomingMatches.assignAll(matches);
      } else {
        upcomingMatches.addAll(matches);
      }
      hasMoreUpcoming.value = (scheduled?.hasNextPage ?? false) ||
          (negotiating?.hasNextPage ?? false);
    } finally {
      isLoadingMatches.value = false;
    }
  }

  Future<void> loadMoreHistory() async {
    if (!hasMoreHistory.value || isLoadingMatches.value) return;
    historyPage.value++;
    await _loadHistory();
  }

  Future<void> loadMoreUpcoming() async {
    if (!hasMoreUpcoming.value || isLoadingMatches.value) return;
    upcomingPage.value++;
    await _loadUpcoming();
  }

  Future<void> reload() async {
    await _loadMyTeams();
  }
}
