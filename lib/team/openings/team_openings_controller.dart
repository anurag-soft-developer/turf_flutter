import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import '../../core/utils/app_snackbar.dart';

class TeamOpeningsController extends GetxController
    with SegmentedTabCacheController<TeamSportType, TeamModel> {
  final TeamService _teamService = TeamService();

  final Rx<TeamSportType> selectedSport = TeamSportType.cricket.obs;
  final Map<String, TeamMemberModel> myMembershipByTeamId =
      <String, TeamMemberModel>{};
  final RxBool myMembershipsLoaded = false.obs;
  final joiningTeamIds = <String>[].obs;

  @override
  List<TeamSportType> get tabKeys => TeamSportType.values;

  @override
  void onInit() {
    super.onInit();
    ensureSportLoaded(selectedSport.value);
    refreshMyMemberships();
  }

  void switchSport(TeamSportType sport) {
    if (selectedSport.value == sport) return;
    selectedSport.value = sport;
    ensureSportLoaded(sport);
  }

  SegmentedTabDataState<TeamModel> stateForSport(TeamSportType sport) {
    return tabStateFor(sport);
  }

  Future<void> ensureSportLoaded(TeamSportType sport) async {
    await ensureTabLoaded(sport);
  }

  Future<void> reloadSport(TeamSportType sport) async {
    await ensureTabLoaded(sport, force: true);
  }

  Future<void> refreshMyMemberships() async {
    myMembershipsLoaded.value = false;
    try {
      final result = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(limit: 100),
      );
      myMembershipByTeamId
        ..clear()
        ..addEntries(
          (result?.data ?? const <TeamMemberModel>[])
              .map((m) {
                final id = m.teamId;
                if (id == null || id.isEmpty) return null;
                return MapEntry(id, m);
              })
              .whereType<MapEntry<String, TeamMemberModel>>(),
        );
    } finally {
      myMembershipsLoaded.value = true;
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
        return 'On team';
      case TeamMemberStatus.pending:
        return 'Pending';
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
    return m.status == TeamMemberStatus.rejected ||
        m.status == TeamMemberStatus.resigned ||
        m.status == TeamMemberStatus.removed;
  }

  /// Join (or re-request after reject). No-op if already active or pending.
  Future<void> requestJoin(String teamId) async {
    final m = membershipForTeam(teamId);
    if (m != null &&
        (m.status == TeamMemberStatus.active ||
            m.status == TeamMemberStatus.pending)) {
      return;
    }
    if (joiningTeamIds.contains(teamId)) return;
    joiningTeamIds.add(teamId);
    try {
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
        await ensureTabLoaded(selectedSport.value, force: true);
        await refreshMyMemberships();
      } else {
        AppSnackbar.error(
          title: 'Request failed',
          message: 'Unable to send join request. Try again later.',
        );
      }
    } finally {
      joiningTeamIds.remove(teamId);
    }
  }

  @override
  Future<List<TeamModel>> fetchTabItems(TeamSportType sport) async {
    final page = await _teamService.findMany(
      TeamFilterQuery(
        status: TeamStatus.active,
        visibility: TeamVisibility.public,
        sportType: sport,
        lookingForMembers: true,
        page: 1,
        limit: 50,
      ),
    );
    return page?.data ?? <TeamModel>[];
  }

  @override
  String mapFetchError(Object error) {
    return 'Failed to load recruiting teams';
  }
}
