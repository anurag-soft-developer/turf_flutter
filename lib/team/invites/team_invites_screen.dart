import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../components/shared/confirm_phone_dialog.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/utils/app_snackbar.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import 'model/team_invite_model.dart';
import 'team_invites_controller.dart';

class TeamInvitesScreen extends HookWidget {
  const TeamInvitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamInvitesController>();
    final teamId = c.teamId;
    final hasTeamId = teamId != null && teamId.isNotEmpty;
    final teamService = TeamService();

    final teamQuery = useQuery<TeamModel, Object>(
      QueryKeys.teamDetail(teamId ?? ''),
      (_) async {
        final team = await teamService.findById(teamId!);
        if (team == null) throw Exception('Team not found');
        return team;
      },
      enabled: hasTeamId,
      retry: noRetry,
    );

    final invitesQuery = useQuery<PaginatedResponse<TeamInviteModel>, Object>(
      QueryKeys.teamInvites(teamId ?? ''),
      (_) async {
        final page = await teamService.inviteService.listForTeam(
          teamId!,
          const TeamInviteFilterQuery(limit: 100),
        );
        return page ?? EmptyPaginatedResponse<TeamInviteModel>();
      },
      enabled: hasTeamId,
      retry: noRetry,
    );

    final uid = Get.find<AuthStateController>().user?.id;
    final team = teamQuery.data;
    final accessDenied = !hasTeamId ||
        (teamQuery.isSuccess &&
            (team == null || uid == null || !team.isOwner(uid)));

    useEffect(() {
      c.syncAccessDenied(accessDenied);
      c.syncTeamName(team?.name);
      return null;
    }, [accessDenied, team?.name]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(
          team?.name != null ? 'Invites · ${team!.name}' : 'Invites',
        ),
      ),
      floatingActionButton: accessDenied
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showInviteSheet(context, c),
              backgroundColor: const Color(AppColors.primaryColor),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Invite'),
            ),
      body: _buildBody(
        context: context,
        c: c,
        hasTeamId: hasTeamId,
        accessDenied: accessDenied,
        teamQuery: teamQuery,
        invitesQuery: invitesQuery,
      ),
    );
  }

  Future<void> _showInviteSheet(
    BuildContext context,
    TeamInvitesController c,
  ) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(AppColors.surfaceColor),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Invite by email or phone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter an email address or phone number with country code.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: const TextStyle(
                  color: Color(AppColors.textColor),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'email@example.com or +9198…',
                  hintStyle: const TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                  ),
                  filled: true,
                  fillColor: const Color(AppColors.surfaceColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final busy = c.inviting.value;
                return FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          try {
                            final identifier = await resolveAuthIdentifier(
                              ctx,
                              controller.text,
                            );
                            if (identifier == null) return;
                            final ok = await c.invite(
                              email: identifier.email,
                              phone: identifier.phone,
                            );
                            if (ok && ctx.mounted) {
                              Navigator.of(ctx).pop(true);
                            }
                          } on FormatException catch (e) {
                            AppSnackbar.error(
                              title: 'Invalid contact',
                              message: e.message,
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send invite'),
                );
              }),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (result == true) {
      // list invalidated by controller
    }
  }

  Widget _buildBody({
    required BuildContext context,
    required TeamInvitesController c,
    required bool hasTeamId,
    required bool accessDenied,
    required QueryResult<TeamModel, Object> teamQuery,
    required QueryResult<PaginatedResponse<TeamInviteModel>, Object>
        invitesQuery,
  }) {
    if (!hasTeamId || accessDenied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You do not have access to manage invites for this team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    if (teamQuery.isLoading ||
        (invitesQuery.isLoading && invitesQuery.data == null)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (invitesQuery.isError && invitesQuery.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load invites',
              style: TextStyle(color: Color(AppColors.textSecondaryColor)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => invitesQuery.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = List<TeamInviteModel>.from(invitesQuery.data?.data ?? [])
      ..sort((a, b) {
        int rank(TeamInviteStatus s) => switch (s) {
              TeamInviteStatus.pending => 0,
              TeamInviteStatus.accepted => 1,
              TeamInviteStatus.rejected => 2,
              TeamInviteStatus.revoked => 3,
              TeamInviteStatus.expired => 4,
            };
        final cmp = rank(a.status).compareTo(rank(b.status));
        if (cmp != 0) return cmp;
        return (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0));
      });

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => invitesQuery.refetch(),
        color: const Color(AppColors.primaryColor),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No invites yet.\nTap Invite to send one by email or phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => invitesQuery.refetch(),
      color: const Color(AppColors.primaryColor),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final invite = items[index];
          return _InviteRow(invite: invite, controller: c);
        },
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.controller});

  final TeamInviteModel invite;
  final TeamInvitesController controller;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_jm();
    final created = invite.createdAt != null
        ? dateFmt.format(invite.createdAt!.toLocal())
        : null;

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    const Color(AppColors.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                invite.email != null
                    ? Icons.email_outlined
                    : Icons.phone_outlined,
                color: const Color(AppColors.primaryColor),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invite.contactLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      _statusLabel(invite.status),
                      if (created != null) created,
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
            if (invite.status == TeamInviteStatus.pending)
              Obx(() {
                final busy = controller.actionInviteId.value == invite.id;
                return TextButton(
                  onPressed: busy ? null : () => controller.revoke(invite),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Revoke'),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TeamInviteStatus s) => switch (s) {
        TeamInviteStatus.pending => 'Pending',
        TeamInviteStatus.accepted => 'Accepted',
        TeamInviteStatus.rejected => 'Rejected',
        TeamInviteStatus.expired => 'Expired',
        TeamInviteStatus.revoked => 'Revoked',
      };
}
