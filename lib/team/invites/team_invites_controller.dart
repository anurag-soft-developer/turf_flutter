import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';
import 'model/team_invite_model.dart';

/// Owner-only: sent invites for a team.
class TeamInvitesController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxnString actionInviteId = RxnString();
  final RxBool inviting = false.obs;
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

  Future<bool> invite({String? email, String? phone}) async {
    if (_teamId == null) return false;
    inviting.value = true;
    final res = await _teamService.inviteService.create(
      _teamId!,
      CreateTeamInviteRequest(email: email, phone: phone),
    );
    inviting.value = false;
    if (res == null) return false;

    AppSnackbar.success(
      title: 'Invite sent',
      message: email != null
          ? 'Invitation email sent to $email.'
          : 'Invitation SMS sent to $phone.',
    );
    await _invalidateInvites();
    return true;
  }

  Future<void> revoke(TeamInviteModel invite) async {
    if (_teamId == null) return;
    final id = invite.id;
    if (id == null || id.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot revoke',
        message: 'Missing invite id.',
      );
      return;
    }
    actionInviteId.value = id;
    final ok = await _teamService.inviteService.revoke(_teamId!, id);
    if (ok) {
      AppSnackbar.success(
        title: 'Invite revoked',
        message: 'The invitation was cancelled.',
      );
      await _invalidateInvites();
    }
    actionInviteId.value = null;
  }

  Future<void> _invalidateInvites() async {
    final id = _teamId;
    if (id == null || !Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(queryKey: ['teamInvites', id]),
      client.invalidateQueries(queryKey: const ['myInvitations']),
      client.invalidateQueries(
        queryKey: QueryKeys.teamRoster(id, status: TeamMemberStatus.active.name),
      ),
    ]);
  }
}
