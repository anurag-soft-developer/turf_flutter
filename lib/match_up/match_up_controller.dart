import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../team/members/model/team_member_model.dart';
import '../team/model/team_model.dart';
import 'matchmaking_service.dart';
import 'model/team_match_model.dart';

/// UI-only Match Up state. List fetching is owned by flutter_query on the screen.
class MatchUpController extends GetxController {
  final MatchmakingService _matchmakingService = MatchmakingService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final RxBool isSendingRequest = false.obs;
  final RxList<TeamMemberModel> myMemberships = <TeamMemberModel>[].obs;
  final Rx<TeamMemberFieldInstance?> selectedTeam =
      Rx<TeamMemberFieldInstance?>(null);
  final RxInt feedRevision = 0.obs;

  /// Opponent team ids challenged by the current [selectedTeam] (immediate UI).
  final RxMap<String, Set<String>> challengedOpponentsByFromTeam =
      <String, Set<String>>{}.obs;

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

  void syncMemberships(List<TeamMemberModel> memberships) {
    myMemberships.assignAll(memberships);
    _autoSelectTeam();
  }

  void bumpFeed() => feedRevision.value++;

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    _autoSelectTeam();
    bumpFeed();
  }

  void selectTeam(TeamMemberFieldInstance team) {
    if (selectedTeam.value?.id == team.id) return;
    selectedTeam.value = team;
    bumpFeed();
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

  void _autoSelectTeam() {
    final teams = myTeamsForSport;
    if (teams.isEmpty) {
      selectedTeam.value = null;
    } else if (selectedTeam.value == null ||
        !teams.any((t) => t.id == selectedTeam.value!.id)) {
      selectedTeam.value = teams.first;
    }
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
        if (Get.isRegistered<QueryClient>()) {
          await Get.find<QueryClient>().invalidateQueries(
            queryKey: const ['matchUpOpponents'],
          );
        }
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
