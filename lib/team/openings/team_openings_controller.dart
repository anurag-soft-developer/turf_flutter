import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// UI + join mutation state. List fetching is owned by flutter_query on the screen.
class TeamOpeningsController extends GetxController {
  final TeamService _teamService = TeamService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final Map<String, TeamMemberModel> myMembershipByTeamId =
      <String, TeamMemberModel>{};
  final RxBool myMembershipsLoaded = false.obs;
  final joiningTeamIds = <String>[].obs;

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
  }

  void syncMemberships(List<TeamMemberModel> memberships) {
    myMembershipByTeamId
      ..clear()
      ..addEntries(
        memberships
            .map((m) {
              final id = m.teamId;
              if (id == null || id.isEmpty) return null;
              return MapEntry(id, m);
            })
            .whereType<MapEntry<String, TeamMemberModel>>(),
      );
    myMembershipsLoaded.value = true;
  }

  TeamMemberModel? membershipForTeam(String? teamId) {
    if (teamId == null || teamId.isEmpty) return null;
    return myMembershipByTeamId[teamId];
  }

  String? joinButtonLabel(String teamId) {
    final m = membershipForTeam(teamId);
    if (m == null) return 'Join';
    switch (m.status) {
      case TeamMemberStatus.active:
        return 'On team';
      case TeamMemberStatus.pending:
        return 'Withdraw';
      case TeamMemberStatus.rejected:
        return 'Join again';
      case TeamMemberStatus.resigned:
      case TeamMemberStatus.removed:
      case TeamMemberStatus.suspended:
        return 'Join';
    }
  }

  bool canTapJoin(String teamId) {
    final m = membershipForTeam(teamId);
    if (m == null) return true;
    return m.status == TeamMemberStatus.pending ||
        m.status == TeamMemberStatus.rejected ||
        m.status == TeamMemberStatus.resigned ||
        m.status == TeamMemberStatus.removed;
  }

  Future<void> onJoinAction(String teamId) async {
    final m = membershipForTeam(teamId);
    if (m?.status == TeamMemberStatus.pending) {
      await withdrawJoinRequest(teamId);
      return;
    }
    await requestJoin(teamId);
  }

  Future<void> requestJoin(String teamId) async {
    final m = membershipForTeam(teamId);
    if (m != null &&
        (m.status == TeamMemberStatus.active ||
            m.status == TeamMemberStatus.pending ||
            m.status == TeamMemberStatus.suspended)) {
      return;
    }
    if (joiningTeamIds.contains(teamId)) return;
    joiningTeamIds.add(teamId);
    final result = await _teamService.memberService.join(teamId);
    if (result != null) {
      final id = result.teamId;
      if (id != null) myMembershipByTeamId[id] = result;
      AppSnackbar.success(
        title: 'Request sent',
        message: result.status == TeamMemberStatus.active
            ? 'You have joined the team.'
            : 'Your join request was submitted.',
      );
      await _invalidateJoinQueries();
    }
    joiningTeamIds.remove(teamId);
  }

  Future<void> withdrawJoinRequest(String teamId) async {
    final m = membershipForTeam(teamId);
    if (m == null || m.status != TeamMemberStatus.pending) return;
    if (joiningTeamIds.contains(teamId)) return;
    joiningTeamIds.add(teamId);
    final ok = await _teamService.memberService.withdrawJoinRequest(teamId);
    if (ok) {
      myMembershipByTeamId.remove(teamId);
      AppSnackbar.success(
        title: 'Request withdrawn',
        message: 'Your join request was withdrawn.',
      );
      await _invalidateJoinQueries();
    }
    joiningTeamIds.remove(teamId);
  }

  Future<void> _invalidateJoinQueries() async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(
        queryKey: QueryKeys.teamOpenings(selectedSport.value.name),
      ),
      client.invalidateQueries(queryKey: QueryKeys.myMemberships),
      client.invalidateQueries(queryKey: QueryKeys.myJoinRequests('pending')),
    ]);
  }
}
