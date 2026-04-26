import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// Owner-only: pending join applications for a team.
class TeamJoinRequestsController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxBool isInitialLoading = true.obs;
  final RxBool isBusy = false.obs;
  final RxnString actionMembershipId = RxnString();
  final RxBool accessDenied = false.obs;

  String? _teamId;
  String? get teamId => _teamId;

  final RxnString teamName = RxnString();
  final RxList<TeamMemberModel> pending = <TeamMemberModel>[].obs;

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

  Future<void> _bootstrap() async {
    isInitialLoading.value = true;
    try {
      final t = await _teamService.findById(_teamId!);
      final uid = Get.find<AuthStateController>().user?.id;
      if (t == null || uid == null || !t.isOwner(uid)) {
        accessDenied.value = true;
        return;
      }
      teamName.value = t.name;
      accessDenied.value = false;
      await loadPending();
    } finally {
      isInitialLoading.value = false;
    }
  }

  Future<void> loadPending() async {
    if (_teamId == null) return;
    isBusy.value = true;
    try {
      final page = await _teamService.memberService.listForTeam(
        _teamId!,
        const TeamMemberRosterFilterQuery(
          status: TeamMemberStatus.pending,
          limit: 100,
        ),
      );
      pending.assignAll(page?.data ?? <TeamMemberModel>[]);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> accept(TeamMemberModel m) async {
    if (_teamId == null) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot accept',
        message: 'Missing membership id.',
      );
      return;
    }
    actionMembershipId.value = mid;
    try {
      final res = await _teamService.memberService.acceptRequest(
        _teamId!,
        mid,
      );
      if (res != null) {
        AppSnackbar.success(
          title: 'Player added',
          message: 'They are now a member of the team.',
        );
        await loadPending();
      } else {
        AppSnackbar.error(
          title: 'Could not accept',
          message: 'Try again later.',
        );
      }
    } finally {
      actionMembershipId.value = null;
    }
  }

  Future<void> reject(TeamMemberModel m) async {
    if (_teamId == null) return;
    final mid = m.id;
    if (mid == null || mid.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot reject',
        message: 'Missing membership id.',
      );
      return;
    }
    actionMembershipId.value = mid;
    try {
      final res = await _teamService.memberService.rejectRequest(
        _teamId!,
        mid,
      );
      if (res != null) {
        AppSnackbar.success(
          title: 'Request rejected',
          message: 'The application was rejected.',
        );
        await loadPending();
      } else {
        AppSnackbar.error(
          title: 'Could not reject',
          message: 'Try again later.',
        );
      }
    } finally {
      actionMembershipId.value = null;
    }
  }
}
