import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../components/rankings/player_avatar.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import 'model/team_invite_model.dart';
import 'team_invite_sheet.dart';
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
      floatingActionButton: accessDenied
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final pending = invitesQuery.data?.data ?? const [];
                final targets = <String>{};
                for (final invite in pending) {
                  if (invite.status != TeamInviteStatus.pending) continue;
                  final userId = invite.inviteeHelper.getId();
                  if (userId != null && userId.isNotEmpty) {
                    targets.add(userId);
                  }
                  final contact = TeamInvitesController.contactKey(
                    email: invite.email,
                    phone: invite.phone,
                  );
                  if (contact.isNotEmpty) targets.add(contact);
                }
                showTeamInviteSheet(
                  context: context,
                  controller: c,
                  alreadyInvitedTargets: targets,
                );
              },
              backgroundColor: const Color(AppColors.primaryColor),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Invite'),
            ),
      body: RefreshIndicator(
        edgeOffset: floatingRefreshEdgeOffset(context),
        onRefresh: () => invitesQuery.refetch(),
        color: const Color(AppColors.primaryColor),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            FloatingSliverAppBar(
              title: Text(
                team?.name != null ? 'Invites · ${team!.name}' : 'Invites',
              ),
            ),
            ..._bodySlivers(
              context: context,
              c: c,
              hasTeamId: hasTeamId,
              accessDenied: accessDenied,
              teamQuery: teamQuery,
              invitesQuery: invitesQuery,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bodySlivers({
    required BuildContext context,
    required TeamInvitesController c,
    required bool hasTeamId,
    required bool accessDenied,
    required QueryResult<TeamModel, Object> teamQuery,
    required QueryResult<PaginatedResponse<TeamInviteModel>, Object>
        invitesQuery,
  }) {
    if (!hasTeamId || accessDenied) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'You do not have access to manage invites for this team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    if (teamQuery.isLoading ||
        (invitesQuery.isLoading && invitesQuery.data == null)) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          ),
        ),
      ];
    }

    if (invitesQuery.isError && invitesQuery.data == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ];
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
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No invites yet.\nTap Invite to search people or send by email/phone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                child: _InviteRow(invite: items[index], controller: c),
              );
            },
            childCount: items.length,
          ),
        ),
      ),
    ];
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
    final invitee = invite.inviteeHelper;
    final showUser = invitee.isPopulated;

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            if (showUser)
              PlayerAvatar(
                url: invitee.getAvatar() ?? '',
                name: invitee.getDisplayName(),
                size: 44,
                userId: invitee.getId(),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryColor)
                      .withValues(alpha: 0.1),
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
