import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';

/// Unified controller for both "My Team" and "Team Profile" screens.
///
/// [isMyTeamMode] = true  → no teamId argument; screen resolves the current
///                          user's active-membership team; shows empty state when none.
/// [isMyTeamMode] = false → expects `Get.arguments['teamId']`; loads that team.
///
/// Fetching is owned by flutter_query on the screen; this controller holds
/// mutation busy flags and synced query data for Obx UI.
class TeamDetailController extends GetxController {
  final bool isMyTeamMode;

  TeamDetailController({this.isMyTeamMode = false});

  final TeamService _teamService = TeamService();

  final Rxn<TeamModel> team = Rxn<TeamModel>();
  final RxList<TeamMemberModel> members = <TeamMemberModel>[].obs;
  final Rxn<TeamMemberModel> myMembership = Rxn<TeamMemberModel>();

  final RxBool isActionLoading = false.obs;
  final RxBool isUpdatingTeamSettings = false.obs;
  final RxBool isJoining = false.obs;

  String? _teamId;

  String? get teamId => _teamId;

  bool get isOwner {
    final t = team.value;
    final uid = Get.find<AuthStateController>().user?.id;
    if (t == null || uid == null) return false;
    return t.isOwner(uid);
  }

  bool get isMember => myMembership.value?.status == TeamMemberStatus.active;

  bool get hasPendingRequest =>
      myMembership.value?.status == TeamMemberStatus.pending;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args['teamId'] is String) {
      _teamId = args['teamId'] as String;
    }
  }

  void setTeamId(String? id) {
    _teamId = id;
  }

  void syncTeam(TeamModel? value) {
    team.value = value;
  }

  void syncMembers(List<TeamMemberModel> value) {
    members.assignAll(value);
  }

  void syncMyMembership(TeamMemberModel? value) {
    myMembership.value = value;
  }

  Future<void> refreshData() => _invalidateTeamQueries();

  // ── Owner actions ─────────────────────────────────────────────────────────

  /// Partial update for discovery / join preferences (owner only).
  Future<void> updateTeamSettings({
    TeamVisibility? visibility,
    TeamJoinMode? joinMode,
    bool? lookingForMembers,
    bool? teamOpenForMatch,
    int? maxPendingJoinRequests,
  }) async {
    final id = _teamId;
    final t = team.value;
    if (id == null || !isMyTeamMode || !isOwner || t == null) return;

    final affectsVisibilityOrJoin = visibility != null || joinMode != null;
    if (affectsVisibilityOrJoin) {
      final nextVisibility = visibility ?? t.visibility;
      final nextJoinMode = joinMode ?? t.joinMode;
      if (nextVisibility == TeamVisibility.private &&
          nextJoinMode == TeamJoinMode.open) {
        AppSnackbar.warning(
          title: 'Join mode',
          message:
              'Private teams cannot use open join. Make the team public or use approval.',
        );
        return;
      }
    }

    isUpdatingTeamSettings.value = true;
    try {
      TeamJoinMode? joinModePatch = joinMode;
      TeamVisibility? visibilityPatch = visibility;
      if (visibility == TeamVisibility.private &&
          t.joinMode == TeamJoinMode.open &&
          joinMode == null) {
        joinModePatch = TeamJoinMode.approval;
      }

      final updated = await _teamService.update(
        id,
        UpdateTeamRequest(
          visibility: visibilityPatch,
          joinMode: joinModePatch,
          lookingForMembers: lookingForMembers,
          teamOpenForMatch: teamOpenForMatch,
          maxPendingJoinRequests: maxPendingJoinRequests,
        ),
      );
      if (updated != null) {
        team.value = updated;
        AppSnackbar.success(
          title: 'Settings saved',
          message: 'Team preferences were updated.',
        );
        await _invalidateTeamQueries();
      } else {
        AppSnackbar.error(title: 'Update failed', message: 'Try again later.');
      }
    } finally {
      isUpdatingTeamSettings.value = false;
    }
  }

  Future<void> activateTeam() async {
    final id = _teamId;
    if (id == null || !isMyTeamMode || !isOwner) return;
    isActionLoading.value = true;
    try {
      final updated = await _teamService.update(
        id,
        UpdateTeamRequest(status: TeamStatus.active),
      );
      if (updated != null) {
        AppSnackbar.success(
          title: 'Team activated',
          message: '${updated.name} is now active.',
        );
        await _invalidateTeamQueries();
      } else {
        AppSnackbar.error(
          title: 'Could not activate',
          message: 'Try again later.',
        );
      }
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deactivateTeam() async {
    final id = _teamId;
    if (id == null || !isMyTeamMode || !isOwner) return;
    isActionLoading.value = true;
    try {
      final updated = await _teamService.update(
        id,
        UpdateTeamRequest(status: TeamStatus.inactive),
      );
      if (updated != null) {
        AppSnackbar.success(
          title: 'Team deactivated',
          message: '${updated.name} is now inactive.',
        );
        await _invalidateTeamQueries();
      } else {
        AppSnackbar.error(
          title: 'Could not deactivate',
          message: 'Try again later.',
        );
      }
    } finally {
      isActionLoading.value = false;
    }
  }

  // ── Member actions ────────────────────────────────────────────────────────

  Future<void> leaveTeam() async {
    final id = _teamId;
    if (id == null || !isMyTeamMode || !isMember) return;
    isActionLoading.value = true;
    try {
      final res = await _teamService.memberService.leave(id);
      if (res != null && res.success) {
        AppSnackbar.success(title: 'Left team', message: res.message);
        await _invalidateTeamQueries(
          teamId: id,
          includeJoinRequests: true,
        );
        if (isMyTeamMode) {
          team.value = null;
          members.clear();
          myMembership.value = null;
          _teamId = null;
        }
      } else {
        AppSnackbar.error(
          title: 'Could not leave',
          message: 'Try again later.',
        );
      }
    } finally {
      isActionLoading.value = false;
    }
  }

  // ── Visitor actions ───────────────────────────────────────────────────────

  Future<void> sendJoinRequest() async {
    final id = _teamId;
    if (id == null || isMyTeamMode || isMember || hasPendingRequest) return;
    isJoining.value = true;
    try {
      final result = await _teamService.memberService.join(id);
      if (result != null) {
        myMembership.value = result;
        AppSnackbar.success(
          title: 'Request sent',
          message: result.status == TeamMemberStatus.active
              ? 'You have joined the team.'
              : 'Your join request was submitted.',
        );
        await _invalidateTeamQueries(includeJoinRequests: true);
      } else {
        AppSnackbar.error(
          title: 'Request failed',
          message: 'Unable to send join request. Try again later.',
        );
      }
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> _invalidateTeamQueries({
    String? teamId,
    bool includeJoinRequests = false,
  }) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: QueryKeys.myMemberships),
    ];
    final id = teamId ?? _teamId;
    if (id != null && id.isNotEmpty) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.teamDetail(id)),
      );
      futures.add(
        client.invalidateQueries(queryKey: ['teamRoster', id]),
      );
    }
    if (includeJoinRequests) {
      futures.add(
        client.invalidateQueries(queryKey: const ['myJoinRequests']),
      );
    }
    await Future.wait(futures);
  }
}
