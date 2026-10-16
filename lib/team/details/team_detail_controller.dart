import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/exception_handler.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../../openings/model/enrollment_model.dart';
import '../../openings/model/opening_model.dart';
import '../../openings/opening_service.dart';
import '../team_service.dart';

/// Unified controller for both "My Team" and "Team Profile" screens.
///
/// [isMyTeamMode] = true  → resolves an active membership team when no id yet.
/// [isMyTeamMode] = false → expects `Get.arguments['teamId']`.
class TeamDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final bool isMyTeamMode;

  TeamDetailController({this.isMyTeamMode = false});

  final TeamService _teamService = TeamService();
  final OpeningService _openingService = OpeningService();

  late final TabController tabController;

  final Rxn<TeamModel> team = Rxn<TeamModel>();
  final RxList<TeamMemberModel> members = <TeamMemberModel>[].obs;
  final Rxn<TeamMemberModel> myMembership = Rxn<TeamMemberModel>();

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool hasNoTeam = false.obs;

  final RxBool isActionLoading = false.obs;
  final RxBool isUpdatingTeamSettings = false.obs;
  final RxBool isJoining = false.obs;
  final Rxn<OpeningModel> teamOpening = Rxn<OpeningModel>();

  bool get hasOpenOpening => teamOpening.value?.status == OpeningStatus.open;

  String? _teamId;

  String? get teamId => _teamId;

  bool get isOwner {
    final t = team.value;
    final uid = Get.find<AuthStateController>().user?.id;
    if (t == null || uid == null) return false;
    return t.isOwner(uid);
  }

  bool get isMember => myMembership.value?.status == TeamMemberStatus.active;

  bool get isSuspended =>
      myMembership.value?.status == TeamMemberStatus.suspended;

  /// Active or suspended members can leave the team.
  bool get canLeave => isMember || isSuspended;

  bool get hasPendingRequest =>
      teamOpening.value?.myStatus == EnrollmentStatus.pending;

  bool get hasAcceptedEnrollment =>
      teamOpening.value?.myStatus == EnrollmentStatus.accepted;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments;
    if (args is Map && args['teamId'] is String) {
      final id = (args['teamId'] as String).trim();
      if (id.isNotEmpty) _teamId = id;
    }
    load();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void setTeamId(String? id) {
    // Sticky once known so nested routes (e.g. edit) cannot wipe/swap the team.
    if (id == null || id.isEmpty) return;
    _teamId = id;
  }

  void clearTeamId() {
    _teamId = null;
  }

  Future<void> refreshData() => load();

  Future<void> load() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = null;
    hasNoTeam.value = false;

    try {
      var id = _teamId;
      List<TeamMemberModel>? mine;

      if ((id == null || id.isEmpty) && isMyTeamMode) {
        mine = await _fetchMyMemberships();
        id = _firstActiveTeamId(mine);
        if (id == null || id.isEmpty) {
          hasNoTeam.value = true;
          team.value = null;
          teamOpening.value = null;
          members.clear();
          myMembership.value = null;
          return;
        }
        setTeamId(id);
      }

      if (id == null || id.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'Missing team ID.';
        return;
      }

      final teamFuture = _teamService.findById(id);
      final rosterFuture = _teamService.memberService.listForTeam(
        id,
        const TeamMemberRosterFilterQuery(
          status: TeamMemberStatus.active,
          limit: 100,
        ),
      );

      final TeamModel? loaded;
      final PaginatedResponse<TeamMemberModel>? rosterPage;
      if (mine == null) {
        final results = await Future.wait([
          teamFuture,
          rosterFuture,
          _fetchMyMemberships(),
        ]);
        loaded = results[0] as TeamModel?;
        rosterPage = results[1] as PaginatedResponse<TeamMemberModel>?;
        mine = results[2] as List<TeamMemberModel>;
      } else {
        final results = await Future.wait([teamFuture, rosterFuture]);
        loaded = results[0] as TeamModel?;
        rosterPage = results[1] as PaginatedResponse<TeamMemberModel>?;
      }

      if (loaded == null) {
        hasError.value = true;
        errorMessage.value = 'Team not found';
        team.value = null;
        teamOpening.value = null;
        members.clear();
        myMembership.value = null;
        return;
      }

      final roster = rosterPage?.data ?? const <TeamMemberModel>[];
      team.value = loaded;
      members.assignAll(roster);
      myMembership.value = _membershipForTeam(
        teamId: id,
        roster: roster,
        mine: mine,
      );
      teamOpening.value = await _openingService.findByTarget(
        type: OpeningType.team,
        targetId: id,
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = ExceptionHandler.handleGenericException(e);
      debugPrint('Team detail load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<TeamMemberModel>> _fetchMyMemberships() async {
    final result = await _teamService.memberService.myMemberships(
      const MyTeamMembershipsFilterQuery(limit: 100),
    );
    return result?.data ?? const <TeamMemberModel>[];
  }

  static String? _firstActiveTeamId(List<TeamMemberModel> memberships) {
    for (final m in memberships) {
      if (m.status == TeamMemberStatus.active &&
          m.teamId != null &&
          m.teamId!.isNotEmpty) {
        return m.teamId;
      }
    }
    return null;
  }

  static TeamMemberModel? _membershipForTeam({
    required String teamId,
    required List<TeamMemberModel> roster,
    required List<TeamMemberModel> mine,
  }) {
    final me = Get.find<AuthStateController>().user?.id;
    if (me == null) return null;

    for (final m in roster) {
      if (m.userHelper.getId() == me) return m;
    }
    for (final m in mine) {
      if (m.teamId == teamId) return m;
    }
    return null;
  }

  // ── Owner actions ─────────────────────────────────────────────────────────

  Future<void> updateTeamSettings({TeamVisibility? visibility}) async {
    final id = _teamId;
    final t = team.value;
    if (id == null || !isMyTeamMode || !isOwner || t == null) return;
    if (visibility == null) return;

    isUpdatingTeamSettings.value = true;
    final updated = await _teamService.update(
      id,
      UpdateTeamRequest(visibility: visibility),
    );
    if (updated != null) {
      team.value = updated;
      AppSnackbar.success(
        title: 'Settings saved',
        message: 'Team preferences were updated.',
      );
      await _afterMutation();
    }
    isUpdatingTeamSettings.value = false;
  }

  Future<void> activateTeam() async {
    final id = _teamId;
    if (id == null || !isMyTeamMode || !isOwner) return;
    isActionLoading.value = true;
    final updated = await _teamService.update(
      id,
      UpdateTeamRequest(status: TeamStatus.active),
    );
    if (updated != null) {
      AppSnackbar.success(
        title: 'Team activated',
        message: '${updated.name} is now active.',
      );
      await _afterMutation();
    }
    isActionLoading.value = false;
  }

  Future<void> deactivateTeam() async {
    final id = _teamId;
    if (id == null || !isMyTeamMode || !isOwner) return;
    isActionLoading.value = true;
    final updated = await _teamService.update(
      id,
      UpdateTeamRequest(status: TeamStatus.inactive),
    );
    if (updated != null) {
      AppSnackbar.success(
        title: 'Team deactivated',
        message: '${updated.name} is now inactive.',
      );
      await _afterMutation();
    }
    isActionLoading.value = false;
  }

  // ── Member actions ────────────────────────────────────────────────────────

  Future<void> leaveTeam() async {
    final id = _teamId;
    if (id == null || !canLeave) return;
    isActionLoading.value = true;
    final res = await _teamService.memberService.leave(id);
    if (res != null && res.success) {
      AppSnackbar.success(title: 'Left team', message: res.message);
      await _invalidateSharedQueries(teamId: id, includeJoinRequests: true);
      myMembership.value = null;
      if (isMyTeamMode) {
        team.value = null;
        members.clear();
        clearTeamId();
        hasNoTeam.value = true;
      } else {
        await load();
      }
    }
    isActionLoading.value = false;
  }

  // ── Visitor actions ───────────────────────────────────────────────────────

  Future<void> sendJoinRequest() async {
    final id = _teamId;
    final openingId = teamOpening.value?.id;
    if (id == null ||
        openingId == null ||
        isMyTeamMode ||
        isMember ||
        isSuspended ||
        hasPendingRequest ||
        hasAcceptedEnrollment) {
      return;
    }
    isJoining.value = true;
    final result = await _openingService.enroll(openingId);
    if (result != null) {
      final joined = result.status == EnrollmentStatus.accepted;
      AppSnackbar.success(
        title: joined ? 'Enrolled' : 'Request sent',
        message: joined
            ? 'You have joined the team.'
            : 'Your enrollment is waiting for review.',
      );
      await _afterMutation(includeJoinRequests: true);
    }
    isJoining.value = false;
  }

  Future<void> withdrawJoinRequest() async {
    final openingId = teamOpening.value?.id;
    if (openingId == null || isMyTeamMode || !hasPendingRequest) return;
    isJoining.value = true;
    final ok = await _openingService.withdraw(openingId);
    if (ok) {
      AppSnackbar.success(
        title: 'Request withdrawn',
        message: 'Your enrollment was withdrawn.',
      );
      await _afterMutation(includeJoinRequests: true);
    }
    isJoining.value = false;
  }

  Future<void> _afterMutation({bool includeJoinRequests = false}) async {
    await _invalidateSharedQueries(includeJoinRequests: includeJoinRequests);
    await load();
  }

  Future<void> _invalidateSharedQueries({
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
      futures.add(client.invalidateQueries(queryKey: QueryKeys.teamDetail(id)));
      futures.add(client.invalidateQueries(queryKey: ['teamRoster', id]));
    }
    if (includeJoinRequests) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.myEnrollmentsPrefix),
      );
    }
    await Future.wait(futures);
  }
}
