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
  /// Busy target key: user id, `email:…`, or `phone:…`.
  final RxnString invitingTargetKey = RxnString();
  final RxBool accessDenied = false.obs;
  final RxnString teamName = RxnString();
  /// Targets invited successfully in this session (for Sent UI).
  final RxSet<String> sentInviteTargets = <String>{}.obs;

  String? _teamId;
  String? get teamId => _teamId;

  static String contactKey({String? email, String? phone}) {
    if (email != null && email.isNotEmpty) {
      return 'email:${email.trim().toLowerCase()}';
    }
    if (phone != null && phone.isNotEmpty) {
      return 'phone:${phone.trim()}';
    }
    return '';
  }

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

  Future<bool> invite({
    String? email,
    String? phone,
    String? inviteeUserId,
  }) async {
    if (_teamId == null) return false;
    final targetKey = inviteeUserId != null && inviteeUserId.isNotEmpty
        ? inviteeUserId
        : contactKey(email: email, phone: phone);

    inviting.value = true;
    invitingTargetKey.value = targetKey.isEmpty ? null : targetKey;
    final res = await _teamService.inviteService.create(
      _teamId!,
      CreateTeamInviteRequest(
        email: email,
        phone: phone,
        inviteeUserId: inviteeUserId,
      ),
    );
    inviting.value = false;
    invitingTargetKey.value = null;
    if (res == null) return false;

    if (targetKey.isNotEmpty) {
      sentInviteTargets.add(targetKey);
    }
    await _invalidateInvites();
    return true;
  }

  bool isInviteSent(String targetKey) {
    if (targetKey.isEmpty) return false;
    return sentInviteTargets.contains(targetKey);
  }

  void seedSentTargets(Iterable<String> keys) {
    sentInviteTargets.addAll(keys.where((k) => k.isNotEmpty));
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
      final inviteeId = invite.inviteeHelper.getId();
      if (inviteeId != null && inviteeId.isNotEmpty) {
        sentInviteTargets.remove(inviteeId);
      }
      final contact = contactKey(email: invite.email, phone: invite.phone);
      if (contact.isNotEmpty) {
        sentInviteTargets.remove(contact);
      }
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
