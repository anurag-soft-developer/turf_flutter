import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';

/// Unified controller for both "My Team" and "Team Profile" screens.
///
/// [isMyTeamMode] = true  → no teamId argument; loads the current user's
///                          active-membership team; shows empty state when none.
/// [isMyTeamMode] = false → expects `Get.arguments['teamId']`; loads that team.
class TeamDetailController extends GetxController {
  final bool isMyTeamMode;

  TeamDetailController({this.isMyTeamMode = false});

  final TeamService _teamService = TeamService();

  final Rxn<TeamModel> team = Rxn<TeamModel>();
  final RxList<TeamMemberModel> members = <TeamMemberModel>[].obs;
  final Rxn<TeamMemberModel> myMembership = Rxn<TeamMemberModel>();

  final RxBool isLoading = true.obs;
  final RxBool isActionLoading = false.obs;
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
    if (isMyTeamMode) {
      _loadFromMyMembership();
    } else {
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        _teamId = args['teamId'] as String?;
      }
      if (_teamId != null) {
        load();
      } else {
        isLoading.value = false;
      }
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Load for "My Team" mode: find the user's active membership then load that team.
  Future<void> _loadFromMyMembership() async {
    isLoading.value = true;
    try {
      final memberships = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      final items = memberships?.data ?? [];
      TeamMemberModel? active;
      for (final m in items) {
        if (m.teamId != null && m.teamId!.isNotEmpty) {
          active = m;
          break;
        }
      }

      if (active == null) {
        _teamId = null;
        team.value = null;
        members.clear();
        myMembership.value = null;
        return;
      }

      _teamId = active.teamId;
      myMembership.value = active;
      await _fetchTeamAndRoster(_teamId!);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load (or reload) from the resolved [_teamId].
  Future<void> load() async {
    if (_teamId == null) return;
    isLoading.value = true;
    try {
      await _fetchTeamAndRoster(_teamId!);
      await _resolveMyMembership(_teamId!);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchTeamAndRoster(String id) async {
    team.value = await _teamService.findById(id);
    final roster = await _teamService.memberService.listForTeam(
      id,
      const TeamMemberRosterFilterQuery(
        status: TeamMemberStatus.active,
        limit: 100,
      ),
    );
    members.assignAll(roster?.data ?? []);
  }

  Future<void> _resolveMyMembership(String id) async {
    final me = Get.find<AuthStateController>().user?.id;
    if (me == null) {
      myMembership.value = null;
      return;
    }

    // Fast path: check already-loaded roster.
    for (final m in members) {
      if (m.userHelper.getId() == me) {
        myMembership.value = m;
        return;
      }
    }

    // Slow path: fetch from own memberships.
    final mine = await _teamService.memberService.myMemberships(
      const MyTeamMembershipsFilterQuery(limit: 50),
    );
    for (final m in mine?.data ?? []) {
      if (m.teamId == id) {
        myMembership.value = m;
        return;
      }
    }
    myMembership.value = null;
  }

  // ── Owner actions ─────────────────────────────────────────────────────────

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
        await load();
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
        await load();
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
        if (isMyTeamMode) {
          await _loadFromMyMembership();
        } else {
          await load();
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
        await load();
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
}
