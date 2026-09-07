import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/model/team_model.dart';
import '../../team/team_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

/// Shared challenge send state for Explore team cards.
class ChallengeController extends GetxController {
  final MatchmakingService _matchmakingService = MatchmakingService();

  final RxBool isSendingRequest = false.obs;
  final RxList<TeamMemberModel> myMemberships = <TeamMemberModel>[].obs;
  final Rx<TeamMemberFieldInstance?> selectedTeam =
      Rx<TeamMemberFieldInstance?>(null);

  /// Opponent team ids challenged by a given from-team (immediate UI).
  final RxMap<String, Set<String>> challengedOpponentsByFromTeam =
      <String, Set<String>>{}.obs;

  /// Opponent team ids that challenged a given one of our teams (API-only).
  final RxMap<String, Set<String>> receivedOpponentsByOurTeam =
      <String, Set<String>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    await Future.wait([
      loadMemberships(),
      loadActiveOpponentIds(),
    ]);
  }

  Future<void> loadMemberships() async {
    if (Get.isRegistered<QueryClient>()) {
      final client = Get.find<QueryClient>();
      final cached = client.getQueryData<List<TeamMemberModel>>(
        QueryKeys.myMemberships,
      );
      if (cached != null) {
        syncMemberships(cached);
      }
      try {
        final data = await client.fetchQuery<List<TeamMemberModel>, Object>(
          QueryKeys.myMemberships,
          (_) => _fetchMemberships(),
          retry: noRetry,
        );
        syncMemberships(data);
      } catch (_) {}
      return;
    }

    try {
      syncMemberships(await _fetchMemberships());
    } catch (_) {}
  }

  Future<void> loadActiveOpponentIds() async {
    if (Get.isRegistered<QueryClient>()) {
      final client = Get.find<QueryClient>();
      final cached = client.getQueryData<ActiveOpponentIds>(
        QueryKeys.activeOpponentIds,
      );
      if (cached != null) {
        _hydrateActiveOpponents(cached);
      }
      try {
        final data = await client.fetchQuery<ActiveOpponentIds, Object>(
          QueryKeys.activeOpponentIds,
          (_) => _matchmakingService.listActiveOpponentIds(),
          retry: noRetry,
          staleDuration: StaleDuration.zero,
        );
        _hydrateActiveOpponents(data);
      } catch (_) {}
      return;
    }

    try {
      _hydrateActiveOpponents(
        await _matchmakingService.listActiveOpponentIds(),
      );
    } catch (_) {}
  }

  void _hydrateActiveOpponents(ActiveOpponentIds ids) {
    challengedOpponentsByFromTeam.assignAll(
      ids.sentByTeamId.map((key, value) => MapEntry(key, {...value})),
    );
    receivedOpponentsByOurTeam.assignAll(
      ids.receivedByTeamId.map((key, value) => MapEntry(key, {...value})),
    );
  }

  static Future<List<TeamMemberModel>> _fetchMemberships() async {
    final result = await TeamService().memberService.myMemberships(
      const MyTeamMembershipsFilterQuery(
        status: TeamMemberStatus.active,
        limit: 50,
      ),
    );
    return result?.data ?? const <TeamMemberModel>[];
  }

  List<TeamMemberFieldInstance> myTeamsForSport(TeamSportType sport) {
    final list = <TeamMemberFieldInstance>[];
    for (final m in myMemberships) {
      final t = m.team;
      if (t is TeamMemberFieldInstance && t.sportType == sport) {
        list.add(t);
      }
    }
    return list;
  }

  void syncMemberships(List<TeamMemberModel> memberships) {
    myMemberships.assignAll(memberships);
    _ensureSelectedTeam();
  }

  void selectTeam(TeamMemberFieldInstance team) {
    if (selectedTeam.value?.id == team.id) return;
    selectedTeam.value = team;
  }

  /// Open-for-match opponent that is not the user's own team.
  bool isChallengeableTarget(TeamModel team) {
    if (team.teamOpenForMatch != true) return false;
    final opponentId = team.id;
    if (opponentId == null || opponentId.isEmpty) return false;
    if (_isOwnActiveTeam(opponentId)) return false;
    return true;
  }

  bool hasTeamToChallengeWith(TeamModel team) {
    return _fromTeamsFor(team).isNotEmpty;
  }

  /// Eligible opponent where every same-sport from-team has already sent.
  bool isChallengeSent(TeamModel team) {
    return isChallengeableTarget(team) &&
        hasTeamToChallengeWith(team) &&
        _allPairsSent(team);
  }

  /// Any same-sport team of ours has an active incoming challenge from this opponent.
  bool isReceived(TeamModel team) {
    final opponentId = team.id;
    if (opponentId == null || opponentId.isEmpty) return false;
    return _fromTeamsFor(team).any(
      (t) =>
          receivedOpponentsByOurTeam[t.id]?.contains(opponentId) ?? false,
    );
  }

  bool _isOwnActiveTeam(String teamId) {
    return myMemberships.any((m) {
      final t = m.team;
      return t is TeamMemberFieldInstance && t.id == teamId;
    });
  }

  List<TeamMemberFieldInstance> _fromTeamsFor(TeamModel opponent) {
    return myTeamsForSport(opponent.sportType)
        .where((t) => t.id != null && t.id != opponent.id)
        .toList();
  }

  bool _allPairsSent(TeamModel opponent) {
    final opponentId = opponent.id;
    if (opponentId == null) return false;
    final fromTeams = _fromTeamsFor(opponent);
    if (fromTeams.isEmpty) return false;
    return fromTeams.every((t) => _isPairChallenged(t.id, opponentId));
  }

  bool _isPairChallenged(String? fromTeamId, String opponentTeamId) {
    if (fromTeamId == null || fromTeamId.isEmpty) return false;
    return challengedOpponentsByFromTeam[fromTeamId]?.contains(
          opponentTeamId,
        ) ??
        false;
  }

  void _markTeamChallenged(String fromTeamId, String opponentTeamId) {
    final existing = challengedOpponentsByFromTeam[fromTeamId] ?? <String>{};
    challengedOpponentsByFromTeam[fromTeamId] = {...existing, opponentTeamId};
    challengedOpponentsByFromTeam.refresh();

    if (!Get.isRegistered<QueryClient>()) return;
    Get.find<QueryClient>().setQueryData<ActiveOpponentIds, Object>(
      QueryKeys.activeOpponentIds,
      (previous) {
        final sent = <String, Set<String>>{
          for (final e
              in (previous?.sentByTeamId ?? challengedOpponentsByFromTeam)
                  .entries)
            e.key: {...e.value},
        };
        sent[fromTeamId] = {...(sent[fromTeamId] ?? {}), opponentTeamId};
        return ActiveOpponentIds(
          sentByTeamId: sent,
          receivedByTeamId: {
            for (final e
                in (previous?.receivedByTeamId ?? receivedOpponentsByOurTeam)
                    .entries)
              e.key: {...e.value},
          },
        );
      },
    );
  }

  void _ensureSelectedTeam() {
    final selected = selectedTeam.value;
    if (selected == null) return;
    final stillMine = myMemberships.any((m) {
      final t = m.team;
      return t is TeamMemberFieldInstance && t.id == selected.id;
    });
    if (!stillMine) {
      selectedTeam.value = null;
    }
  }

  /// Pick a same-sport from-team that has not yet challenged [opponent].
  void prepareForOpponent(TeamModel opponent) {
    final teams = _fromTeamsFor(opponent);
    if (teams.isEmpty) {
      selectedTeam.value = null;
      return;
    }

    final current = selectedTeam.value;
    final currentValid = current != null &&
        teams.any((t) => t.id == current.id) &&
        !_isPairChallenged(current.id, opponent.id ?? '');
    if (currentValid) return;

    selectedTeam.value = teams.firstWhere(
      (t) => !_isPairChallenged(t.id, opponent.id ?? ''),
      orElse: () => teams.first,
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
