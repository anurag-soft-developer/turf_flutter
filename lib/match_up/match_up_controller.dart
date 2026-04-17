import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../team/members/model/team_member_model.dart';
import '../team/model/team_model.dart';
import '../team/team_service.dart';
import 'matchmaking_service.dart';
import 'model/team_match_model.dart';

class MatchUpController extends GetxController {
  final TeamService _teamService = TeamService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final RxBool isLoadingMyTeams = true.obs;
  final RxBool isLoadingFeed = false.obs;
  final RxBool isSendingRequest = false.obs;
  final RxList<TeamMemberModel> myMemberships = <TeamMemberModel>[].obs;
  final RxList<TeamModel> feedTeams = <TeamModel>[].obs;
  final Rx<TeamMemberFieldInstance?> selectedTeam =
      Rx<TeamMemberFieldInstance?>(null);

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

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    _autoSelectTeam();
    _loadFeed();
  }

  void selectTeam(TeamMemberFieldInstance team) {
    if (selectedTeam.value?.id == team.id) return;
    selectedTeam.value = team;
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

  Future<void> _loadFeed() async {
    isLoadingFeed.value = true;
    try {
      final result = await _teamService.findMany(
        TeamFilterQuery(
          sportType: selectedSport.value,
          teamOpenForMatch: true,
          status: TeamStatus.active,
          visibility: TeamVisibility.public,
          limit: 50,
        ),
      );
      final myId = selectedTeam.value?.id;
      final teams = (result?.data ?? []).where((t) => t.id != myId).toList();
      feedTeams.assignAll(teams);
    } finally {
      isLoadingFeed.value = false;
    }
  }

  Future<void> reload() async {
    await _loadMyTeams();
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
        _loadFeed();
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
