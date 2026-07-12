import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/components/query/query_async_body.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import '../utils/team_ui.dart';
import 'team_join_requests_controller.dart';

Duration? _noRetry(int count, Object error) => null;

class TeamJoinRequestsScreen extends HookWidget {
  const TeamJoinRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamJoinRequestsController>();
    final teamId = c.teamId;
    final hasTeamId = teamId != null && teamId.isNotEmpty;
    final teamService = TeamService();

    final teamQuery = useQuery<TeamModel?, Object>(
      QueryKeys.teamDetail(teamId ?? ''),
      (_) => teamService.findById(teamId!),
      enabled: hasTeamId,
      retry: _noRetry,
    );

    final pendingQuery =
        useQuery<PaginatedResponse<TeamMemberModel>, Object>(
      QueryKeys.teamRoster(
        teamId ?? '',
        status: TeamMemberStatus.pending.name,
      ),
      (_) async {
        final page = await teamService.memberService.listForTeam(
          teamId!,
          const TeamMemberRosterFilterQuery(
            status: TeamMemberStatus.pending,
            limit: 100,
          ),
        );
        return page ?? EmptyPaginatedResponse<TeamMemberModel>();
      },
      enabled: hasTeamId,
      retry: _noRetry,
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
          team?.name != null
              ? 'Join requests · ${team!.name}'
              : 'Join requests',
        ),
      ),
      body: _buildBody(
        context: context,
        c: c,
        hasTeamId: hasTeamId,
        accessDenied: accessDenied,
        teamQuery: teamQuery,
        pendingQuery: pendingQuery,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required TeamJoinRequestsController c,
    required bool hasTeamId,
    required bool accessDenied,
    required QueryResult<TeamModel?, Object> teamQuery,
    required QueryResult<PaginatedResponse<TeamMemberModel>, Object>
        pendingQuery,
  }) {
    if (!hasTeamId) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You do not have access to review join requests for this team.',
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
        (teamQuery.isFetching && teamQuery.data == null && !teamQuery.isError)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (teamQuery.isError && teamQuery.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load team',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => teamQuery.refetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (accessDenied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You do not have access to review join requests for this team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return QueryAsyncBody<PaginatedResponse<TeamMemberModel>, Object>(
      state: pendingQuery,
      onRetry: () => pendingQuery.refetch(),
      data: (page) {
        final pending = page.data;
        if (pending.isEmpty) {
          return const Center(
            child: Text(
              'No pending join requests.',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 15,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              teamQuery.refetch(),
              pendingQuery.refetch(),
            ]);
          },
          child: Obx(() {
            final actionId = c.actionMembershipId.value;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = pending[i];
                return _PendingApplicantRow(
                  member: m,
                  onOpenProfile: () {
                    final userId = m.userHelper.getId();
                    if (userId == null || userId.isEmpty) return;
                    Get.toNamed(
                      AppConstants.routes.teamMemberProfile,
                      arguments: {'userId': userId},
                    );
                  },
                  isProcessing: actionId != null && actionId == m.id,
                  onAccept: () => c.accept(m),
                  onReject: () => _confirmReject(context, c, m),
                );
              },
            );
          }),
        );
      },
    );
  }

  void _confirmReject(
    BuildContext context,
    TeamJoinRequestsController c,
    TeamMemberModel m,
  ) {
    final name = m.userHelper.getDisplayName();
    Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject request?'),
        content: Text('Turn down $name’s application?'),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              c.reject(m);
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: Color(AppColors.errorColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApplicantRow extends StatelessWidget {
  const _PendingApplicantRow({
    required this.member,
    required this.onOpenProfile,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  final TeamMemberModel member;
  final VoidCallback onOpenProfile;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final h = member.userHelper;
    final avatar = h.getAvatar();
    final name = h.getDisplayName();
    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpenProfile,
              borderRadius: BorderRadius.circular(999),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(
                  AppColors.primaryColor,
                ).withValues(alpha: 0.12),
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Color(AppColors.primaryColor),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onOpenProfile,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamMemberStatusLabel(TeamMemberStatus.pending),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(AppColors.successColor),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
