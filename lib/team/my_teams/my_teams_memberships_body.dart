import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';
import '../utils/team_ui.dart';

/// Shared infinite list of the user's active team memberships.
class MyTeamsMembershipsBody extends HookWidget {
  const MyTeamsMembershipsBody({
    super.key,
    this.search = '',
    this.bottomPadding = 96,
    this.leadingSlivers = const <Widget>[],
  });

  final String search;
  final double bottomPadding;

  /// When set (e.g. [FloatingSliverAppBar]), uses a single [CustomScrollView].
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    final query =
        useInfiniteQuery<PaginatedResponse<TeamMemberModel>, Object, int>(
      QueryKeys.myMembershipsActive(search: search),
      (ctx) async {
        final result = await TeamService().memberService.myMemberships(
          MyTeamMembershipsFilterQuery(
            status: TeamMemberStatus.active,
            search: search.isEmpty ? null : search,
            page: ctx.pageParam,
            limit: 20,
          ),
        );
        return result ?? EmptyPaginatedResponse<TeamMemberModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final memberships =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <TeamMemberModel>[];

    final useLeading = leadingSlivers.isNotEmpty;

    return RefreshIndicator(
      edgeOffset: useLeading ? floatingRefreshEdgeOffset(context) : 0,
      onRefresh: () => query.refetch(),
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
        child: useLeading
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  ...leadingSlivers,
                  ..._bodySlivers(query, memberships),
                ],
              )
            : _nestedBody(query, memberships),
      ),
    );
  }

  /// Scroll body for [NestedScrollView] (search screen).
  Widget _nestedBody(
    InfiniteQueryResult<PaginatedResponse<TeamMemberModel>, Object, int> query,
    List<TeamMemberModel> memberships,
  ) {
    if (query.isLoading || (query.isFetching && memberships.isEmpty)) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          ),
        ],
      );
    }

    if (query.isError && memberships.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Failed to load teams',
                  style: TextStyle(color: Color(AppColors.textSecondaryColor)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => query.refetch(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (memberships.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _EmptyState(hasSearch: search.isNotEmpty),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      itemCount: memberships.length + (query.isFetchingNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= memberships.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _TeamCard(membership: memberships[index]),
        );
      },
    );
  }

  List<Widget> _bodySlivers(
    InfiniteQueryResult<PaginatedResponse<TeamMemberModel>, Object, int> query,
    List<TeamMemberModel> memberships,
  ) {
    if (query.isLoading || (query.isFetching && memberships.isEmpty)) {
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

    if (query.isError && memberships.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Failed to load teams',
                  style: TextStyle(color: Color(AppColors.textSecondaryColor)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => query.refetch(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (memberships.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyState(hasSearch: search.isNotEmpty),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= memberships.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                child: _TeamCard(membership: memberships[index]),
              );
            },
            childCount:
                memberships.length + (query.isFetchingNextPage ? 1 : 0),
          ),
        ),
      ),
    ];
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.membership});

  final TeamMemberModel membership;

  @override
  Widget build(BuildContext context) {
    final teamRef = membership.team;
    final String teamName;
    final String? logo;
    final TeamSportType? sportType;
    final String? teamId;

    if (teamRef is TeamMemberFieldInstance) {
      teamName = teamRef.name;
      logo = teamRef.logo.isNotEmpty ? teamRef.logo : null;
      sportType = teamRef.sportType;
      teamId = teamRef.id;
    } else {
      teamName = 'Unknown team';
      logo = null;
      sportType = null;
      teamId = membership.teamId;
    }

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: teamId == null || teamId.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.myTeam,
                arguments: {'teamId': teamId},
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: logo != null
                    ? AppNetworkImage(
                        logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _teamInitials(teamName),
                      )
                    : _teamInitials(teamName),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sportType != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        teamSportLabel(sportType),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(AppColors.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamInitials(String name) {
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    if (hasSearch) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 80),
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Color(AppColors.textSecondaryColor),
            ),
            SizedBox(height: 20),
            Text(
              'No teams found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different team name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.groups_2_outlined,
              size: 52,
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No teams yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(AppColors.textColor),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create your own squad or browse\npublic teams and ask to join.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(AppColors.textSecondaryColor),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Create a team',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppConstants.routes.rank),
            icon: const Icon(Icons.search, size: 20),
            label: const Text(
              'Browse teams',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: const Color(AppColors.primaryColor),
              side: const BorderSide(color: Color(AppColors.primaryColor)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
