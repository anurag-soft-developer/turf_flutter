import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../rankings/widgets/rank_sport_filter.dart';
import '../members/model/team_member_model.dart';
import '../model/team_model.dart';
import '../team_service.dart';
import '../utils/team_ui.dart';
import 'team_openings_controller.dart';

class TeamOpeningsScreen extends HookWidget {
  const TeamOpeningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamOpeningsController controller = Get.find();
    final teamService = TeamService();

    final membershipsQuery = useQuery<List<TeamMemberModel>, Object>(
      QueryKeys.myMemberships,
      (_) async {
        final result = await teamService.memberService.myMemberships(
          const MyTeamMembershipsFilterQuery(limit: 100),
        );
        return result?.data ?? const <TeamMemberModel>[];
      },
      retry: noRetry,
    );

    useEffect(() {
      final data = membershipsQuery.data;
      if (data != null) {
        controller.syncMemberships(data);
      }
      return null;
    }, [membershipsQuery.data]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Openings'),
        actions: [
          IconButton(
            tooltip: 'My join requests',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => Get.toNamed(AppConstants.routes.myJoinRequests),
          ),
        ],
      ),
      body: Obx(() {
        final sport = controller.selectedSport.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SportFilterPicker(
                value: sport,
                sports: TeamSportType.values,
                sheetTitle: 'Filter by sport',
                searchable: true,
                onChanged: controller.switchSport,
              ),
            ),
            Expanded(
              child: _OpeningsFeed(
                key: ValueKey(sport.name),
                controller: controller,
                sport: sport,
                onRefreshMemberships: () => membershipsQuery.refetch(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _OpeningsFeed extends HookWidget {
  const _OpeningsFeed({
    super.key,
    required this.controller,
    required this.sport,
    required this.onRefreshMemberships,
  });

  final TeamOpeningsController controller;
  final TeamSportType sport;
  final Future<void> Function() onRefreshMemberships;

  @override
  Widget build(BuildContext context) {
    final query = useInfiniteQuery<PaginatedResponse<TeamModel>, Object, int>(
      QueryKeys.teamOpenings(sport.name),
      (ctx) async {
        final result = await TeamService().findMany(
          TeamFilterQuery(
            status: TeamStatus.active,
            visibility: TeamVisibility.public,
            sportType: sport,
            lookingForMembers: true,
            page: ctx.pageParam,
            limit: 20,
          ),
        );
        return result ?? EmptyPaginatedResponse<TeamModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final items =
        query.data?.pages.expand((p) => p.data).toList() ?? const <TeamModel>[];

    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'Failed to load recruiting teams',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => query.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams are recruiting for this sport yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([query.refetch(), onRefreshMemberships()]);
      },
      color: const Color(AppColors.primaryColor),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 160) {
            if (query.hasNextPage && !query.isFetchingNextPage) {
              query.fetchNextPage();
            }
          }
          return false;
        },
        child: Obx(() {
          controller.myMembershipsLoaded.value;
          controller.joiningTeamIds.length;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final team = items[i];
                    final id = team.id;
                    if (id == null || id.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _RecruitingTeamCard(
                      team: team,
                      label: controller.joinButtonLabel(id) ?? 'Join',
                      onJoin: controller.canTapJoin(id)
                          ? () => controller.onJoinAction(id)
                          : null,
                      isJoining: controller.joiningTeamIds.contains(id),
                    );
                  },
                ),
              ],
              if (query.isFetchingNextPage)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _RecruitingTeamCard extends StatelessWidget {
  const _RecruitingTeamCard({
    required this.team,
    required this.label,
    required this.onJoin,
    required this.isJoining,
  });

  final TeamModel team;
  final String label;
  final VoidCallback? onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    final id = team.id;
    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: id == null || id.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': id},
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeamLogo(url: team.logo, size: 52, teamId: id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textColor),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [_Chip(text: teamJoinModeLabel(team.joinMode))],
                    ),
                    if (team.tagline != null && team.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        team.tagline!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onJoin == null || isJoining ? null : () => onJoin!(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(AppColors.primaryColor).withValues(alpha: 0.12)
            : const Color(AppColors.textSecondaryColor).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: highlighted
              ? const Color(AppColors.primaryColor)
              : const Color(AppColors.textSecondaryColor),
        ),
      ),
    );
  }
}
