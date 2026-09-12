import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// UI + join mutation state. List fetching is owned by flutter_query on the screen.
class TeamOpeningsController extends GetxController {
  final TeamService _teamService = TeamService();

  /// `null` = all sports (no sportType filter).
  final Rxn<TeamSportType> selectedSport = Rxn<TeamSportType>();
  final Map<String, TeamMemberModel> myMembershipByTeamId =
      <String, TeamMemberModel>{};
  final RxBool myMembershipsLoaded = false.obs;

  /// Bumped whenever [myMembershipByTeamId] changes so Obx rebuilds.
  final membershipRevision = 0.obs;
  final joiningTeamIds = <String>[].obs;

  String get openingsQuerySportKey => selectedSport.value?.name ?? 'all';

  void switchSport(TeamSportType? sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
  }

  /// Server returns one newest membership per team when history=false.
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
    membershipRevision.value++;
  }

  void _setMembership(String teamId, TeamMemberModel membership) {
    myMembershipByTeamId[teamId] = membership;
    membershipRevision.value++;
  }

  void _clearMembership(String teamId) {
    if (myMembershipByTeamId.remove(teamId) != null) {
      membershipRevision.value++;
    }
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
      case TeamMemberStatus.suspended:
        return 'Leave';
      case TeamMemberStatus.pending:
        return 'Withdraw';
      case TeamMemberStatus.rejected:
        return 'Join again';
      case TeamMemberStatus.resigned:
      case TeamMemberStatus.removed:
        return 'Join';
    }
  }

  bool canTapJoin(String teamId) {
    final m = membershipForTeam(teamId);
    if (m == null) return true;
    return m.status == TeamMemberStatus.pending ||
        m.status == TeamMemberStatus.active ||
        m.status == TeamMemberStatus.suspended ||
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
    if (m?.status == TeamMemberStatus.active ||
        m?.status == TeamMemberStatus.suspended) {
      await leaveTeam(teamId);
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
      // Always key by the openings card team id (join payload teamId can be null).
      _setMembership(teamId, result);
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
      _clearMembership(teamId);
      await _invalidateJoinQueries();
    }
    joiningTeamIds.remove(teamId);
  }

  Future<void> leaveTeam(String teamId) async {
    final m = membershipForTeam(teamId);
    if (m == null ||
        (m.status != TeamMemberStatus.active &&
            m.status != TeamMemberStatus.suspended)) {
      return;
    }
    if (joiningTeamIds.contains(teamId)) return;
    joiningTeamIds.add(teamId);
    final res = await _teamService.memberService.leave(teamId);
    if (res != null && res.success) {
      _clearMembership(teamId);
      await _invalidateJoinQueries();
    }
    joiningTeamIds.remove(teamId);
  }

  Future<void> _invalidateJoinQueries() async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(queryKey: QueryKeys.myMemberships),
      client.invalidateQueries(queryKey: QueryKeys.myJoinRequests('pending')),
    ]);
  }
}
