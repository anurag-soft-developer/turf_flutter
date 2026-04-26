import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// Owner-only: full roster (active + suspended) with management actions.
class TeamRosterManageController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxBool isInitialLoading = true.obs;
  final RxBool isBusy = false.obs;
  final RxnString actionTargetId = RxnString();
  final RxBool accessDenied = false.obs;

  String? _teamId;
  String? get teamId => _teamId;

  final RxnString teamName = RxnString();
  final RxList<TeamMemberModel> members = <TeamMemberModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['teamId'] is String) {
      _teamId = args['teamId'] as String;
    }
    if (_teamId == null || _teamId!.isEmpty) {
      accessDenied.value = true;
      isInitialLoading.value = false;
      return;
    }
    _bootstrap();
  }

  String? get _me => Get.find<AuthStateController>().user?.id;

  bool isSelf(TeamMemberModel m) {
    final uid = m.userHelper.getId();
    return uid != null && uid == _me;
  }

  Future<void> _bootstrap() async {
    isInitialLoading.value = true;
    try {
      final t = await _teamService.findById(_teamId!);
      final uid = _me;
      if (t == null || uid == null || !t.isOwner(uid)) {
        accessDenied.value = true;
        return;
      }
      teamName.value = t.name;
      accessDenied.value = false;
      await loadMembers();
    } finally {
      isInitialLoading.value = false;
    }
  }

  int _sortMembers(TeamMemberModel a, TeamMemberModel b) {
    const order = {
      TeamMemberStatus.active: 0,
      TeamMemberStatus.suspended: 1,
    };
    final oa = order[a.status] ?? 9;
    final ob = order[b.status] ?? 9;
    if (oa != ob) return oa.compareTo(ob);
    return a.userHelper
        .getDisplayName()
        .toLowerCase()
        .compareTo(b.userHelper.getDisplayName().toLowerCase());
  }

  Future<void> loadMembers() async {
    if (_teamId == null) return;
    isBusy.value = true;
    try {
      final active = await _teamService.memberService.listForTeam(
        _teamId!,
        const TeamMemberRosterFilterQuery(
          status: TeamMemberStatus.active,
          limit: 100,
        ),
      );
      final suspended = await _teamService.memberService.listForTeam(
        _teamId!,
        const TeamMemberRosterFilterQuery(
          status: TeamMemberStatus.suspended,
          limit: 100,
        ),
      );
      final list = <TeamMemberModel>[
        ...(active?.data ?? <TeamMemberModel>[]),
        ...(suspended?.data ?? <TeamMemberModel>[]),
      ]..sort(_sortMembers);
      members.assignAll(list);
    } finally {
      isBusy.value = false;
    }
  }

  void openProfile(TeamMemberModel m) {
    Get.toNamed(
      AppConstants.routes.teamMemberProfile,
      arguments: {'user': m.user},
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
    try {
      final ok = await _teamService.memberService.removeMember(
        _teamId!,
        target,
      );
      if (ok) {
        AppSnackbar.success(
          title: 'Removed',
          message: 'Player was removed from the team.',
        );
        await loadMembers();
      } else {
        AppSnackbar.error(
          title: 'Remove failed',
          message: 'Try again later.',
        );
      }
    } finally {
      actionTargetId.value = null;
    }
  }

  Future<void> suspendMember(TeamMemberModel m) async {
    if (_teamId == null || isSelf(m)) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) return;
    actionTargetId.value = mid;
    try {
      final res = await _teamService.memberService.suspendMember(
        _teamId!,
        mid,
      );
      if (res != null) {
        AppSnackbar.success(
          title: 'Suspended',
          message: 'Player is suspended from the team.',
        );
        await loadMembers();
      } else {
        AppSnackbar.error(
          title: 'Could not suspend',
          message: 'Try again later.',
        );
      }
    } finally {
      actionTargetId.value = null;
    }
  }

  Future<void> unsuspendMember(TeamMemberModel m) async {
    if (_teamId == null) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) return;
    actionTargetId.value = mid;
    try {
      final res = await _teamService.memberService.unsuspendMember(
        _teamId!,
        mid,
      );
      if (res != null) {
        AppSnackbar.success(
          title: 'Restored',
          message: 'Player is active again.',
        );
        await loadMembers();
      } else {
        AppSnackbar.error(
          title: 'Could not unsuspend',
          message: 'Try again later.',
        );
      }
    } finally {
      actionTargetId.value = null;
    }
  }
}
