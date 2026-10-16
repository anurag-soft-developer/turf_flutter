import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../core/query/query_keys.dart';
import '../core/utils/app_snackbar.dart';
import '../team/members/model/team_member_model.dart';
import 'invitation_service.dart';
import 'model/invitation_model.dart';

class MyInvitationsController extends GetxController {
  final InvitationService _service = InvitationService();

  final RxnString actionInviteId = RxnString();
  final Rxn<InvitationKind> kindFilter = Rxn<InvitationKind>();

  void setKindFilter(InvitationKind? kind) {
    kindFilter.value = kind;
  }

  Future<void> accept(InvitationModel invite) async {
    if (invite.id.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot accept',
        message: 'Missing invitation id.',
      );
      return;
    }
    actionInviteId.value = invite.id;
    final ok = await _service.accept(invite);
    if (ok) {
      AppSnackbar.success(
        title: invite.isTournament ? 'Joined tournament' : 'Joined team',
        message: invite.isTournament
            ? '${invite.teamName} joined ${invite.tournamentName ?? 'the tournament'}.'
            : 'You are now a member of ${invite.teamName}.',
      );
      await _invalidate(invite);
    }
    actionInviteId.value = null;
  }

  Future<void> decline(InvitationModel invite) async {
    if (invite.id.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot decline',
        message: 'Missing invitation id.',
      );
      return;
    }
    actionInviteId.value = invite.id;
    final ok = await _service.decline(invite);
    if (ok) {
      AppSnackbar.success(
        title: 'Invite declined',
        message: invite.isTournament
            ? '${invite.teamName} declined ${invite.tournamentName ?? 'the tournament'}.'
            : 'You declined the invitation to ${invite.teamName}.',
      );
      await _invalidate(invite);
    }
    actionInviteId.value = null;
  }

  Future<void> _invalidate(InvitationModel invite) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final futures = <Future>[
      client.invalidateQueries(queryKey: QueryKeys.myInvitationsPrefix),
      client.invalidateQueries(queryKey: QueryKeys.myEnrollmentsPrefix),
    ];
    final teamId = invite.teamId;
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
