import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';
import '../utils/team_ui.dart';

/// Owner-only: full roster (active + suspended) with management actions.
/// Fetching is owned by flutter_query on the screen.
class TeamRosterManageController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxnString actionTargetId = RxnString();
  final RxBool accessDenied = false.obs;
  final RxnString teamName = RxnString();

  String? _teamId;
  String? get teamId => _teamId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['teamId'] is String) {
      _teamId = args['teamId'] as String;
    }
    if (_teamId == null || _teamId!.isEmpty) {
      accessDenied.value = true;
    }
  }

  String? get _me => Get.find<AuthStateController>().user?.id;

  bool isSelf(TeamMemberModel m) {
    final uid = m.userHelper.getId();
    return uid != null && uid == _me;
  }

  void syncTeamName(String? name) {
    teamName.value = name;
  }

  void syncAccessDenied(bool denied) {
    accessDenied.value = denied;
  }

  void openProfile(TeamMemberModel m) {
    final userId = m.userHelper.getId();
    if (userId == null || userId.isEmpty) return;
    Get.toNamed(
      AppConstants.routes.teamMemberProfile,
      arguments: {'userId': userId},
    );
  }

  String? _memberUserId(TeamMemberModel m) {
    return m.userHelper.getId();
  }

  Future<void> removeMember(TeamMemberModel m) async {
    if (_teamId == null || isSelf(m)) return;
    final target = _memberUserId(m);
    if (target == null || target.isEmpty) {
      AppSnackbar.error(
        title: 'Remove failed',
        message: 'Could not read player id.',
      );
      return;
    }
    final mid = m.id;
    if (mid != null) actionTargetId.value = mid;
    final ok = await _teamService.memberService.removeMember(
      _teamId!,
      target,
    );
    if (ok) {
      AppSnackbar.success(
        title: 'Removed',
        message: 'Player was removed from the team.',
      );
      await _invalidateRoster();
    }
    actionTargetId.value = null;
  }

  Future<void> suspendMember(TeamMemberModel m) async {
    if (_teamId == null || isSelf(m)) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) return;
    actionTargetId.value = mid;
    final res = await _teamService.memberService.suspendMember(
      _teamId!,
      mid,
    );
    if (res != null) {
      AppSnackbar.success(
        title: 'Suspended',
        message: 'Player is suspended from the team.',
      );
      await _invalidateRoster();
    }
    actionTargetId.value = null;
  }

  Future<void> unsuspendMember(TeamMemberModel m) async {
    if (_teamId == null) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) return;
    actionTargetId.value = mid;
    final res = await _teamService.memberService.unsuspendMember(
      _teamId!,
      mid,
    );
    if (res != null) {
      AppSnackbar.success(
        title: 'Restored',
        message: 'Player is active again.',
      );
      await _invalidateRoster();
    }
    actionTargetId.value = null;
  }

  Future<void> assignCaptain(TeamMemberModel m) async {
    await _updateLeadershipRole(
      m,
      UpdateTeamMemberRequest(leadershipRole: LeadershipRole.captain),
      'Captain updated',
    );
  }

  Future<void> assignViceCaptain(TeamMemberModel m) async {
    await _updateLeadershipRole(
      m,
      UpdateTeamMemberRequest(leadershipRole: LeadershipRole.viceCaptain),
      'Vice captain updated',
    );
  }

  Future<void> _updateLeadershipRole(
    TeamMemberModel m,
    UpdateTeamMemberRequest request,
    String successTitle,
  ) async {
    if (_teamId == null || m.status != TeamMemberStatus.active) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) return;

    actionTargetId.value = mid;
    final res = await _teamService.memberService.updateMember(
      _teamId!,
      mid,
      request,
    );
    if (res != null) {
      AppSnackbar.success(
        title: successTitle,
        message: '${leadershipRoleLabel(request.leadershipRole)} assigned.',
      );
      await _invalidateRoster();
    }
    actionTargetId.value = null;
  }

  Future<void> _invalidateRoster() async {
    final id = _teamId;
    if (id == null || !Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(queryKey: ['teamRoster', id]),
      client.invalidateQueries(queryKey: QueryKeys.teamDetail(id)),
    ]);
  }
}
