import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';
import 'model/team_invite_model.dart';

/// Invitee: pending invitations with accept / reject.
class MyInvitationsController extends GetxController {
  final TeamService _teamService = TeamService();

  final RxnString actionInviteId = RxnString();

  Future<void> accept(TeamInviteModel invite) async {
    final id = invite.id;
    if (id == null || id.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot accept',
        message: 'Missing invite id.',
      );
      return;
    }
    actionInviteId.value = id;
    final res = await _teamService.inviteService.accept(id);
    if (res != null) {
      AppSnackbar.success(
        title: 'Joined team',
        message: 'You are now a member of ${invite.teamName}.',
      );
      await _invalidate(invite.teamId);
    }
    actionInviteId.value = null;
  }

  Future<void> reject(TeamInviteModel invite) async {
    final id = invite.id;
    if (id == null || id.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot reject',
        message: 'Missing invite id.',
      );
      return;
    }
    actionInviteId.value = id;
    final res = await _teamService.inviteService.reject(id);
    if (res != null) {
      AppSnackbar.success(
        title: 'Invite declined',
        message: 'You declined the invitation to ${invite.teamName}.',
      );
      await _invalidate(invite.teamId);
    }
    actionInviteId.value = null;
  }

  Future<void> _invalidate(String? teamId) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final futures = <Future>[
      client.invalidateQueries(queryKey: const ['myInvitations']),
      client.invalidateQueries(queryKey: const ['myJoinRequests']),
    ];
    if (teamId != null && teamId.isNotEmpty) {
      futures.addAll([
        client.invalidateQueries(queryKey: ['teamInvites', teamId]),
        client.invalidateQueries(
          queryKey: QueryKeys.teamRoster(
            teamId,
            status: TeamMemberStatus.active.name,
          ),
        ),
        client.invalidateQueries(queryKey: QueryKeys.teamDetail(teamId)),
      ]);
    }
    await Future.wait(futures);
  }
}
