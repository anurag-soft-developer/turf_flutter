import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';

/// Owner-only: pending join applications for a team.
/// Fetching is owned by flutter_query on the screen.
class TeamJoinRequestsController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxnString actionMembershipId = RxnString();
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

  void syncTeamName(String? name) {
    teamName.value = name;
  }

  void syncAccessDenied(bool denied) {
    accessDenied.value = denied;
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
    final res = await _teamService.memberService.acceptRequest(
      _teamId!,
      mid,
    );
    if (res != null) {
      AppSnackbar.success(
        title: 'Player added',
        message: 'They are now a member of the team.',
      );
      await _invalidateAfterDecision();
    }
    actionMembershipId.value = null;
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
    final res = await _teamService.memberService.rejectRequest(
      _teamId!,
      mid,
    );
    if (res != null) {
      AppSnackbar.success(
        title: 'Request rejected',
        message: 'The application was rejected.',
      );
      await _invalidateAfterDecision();
    }
    actionMembershipId.value = null;
  }

  Future<void> _invalidateAfterDecision() async {
    final id = _teamId;
    if (id == null || !Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(
        queryKey: QueryKeys.teamRoster(id, status: TeamMemberStatus.pending.name),
      ),
      client.invalidateQueries(
        queryKey: QueryKeys.teamRoster(id, status: TeamMemberStatus.active.name),
      ),
      client.invalidateQueries(queryKey: const ['myJoinRequests']),
      client.invalidateQueries(queryKey: QueryKeys.teamDetail(id)),
    ]);
  }
}
