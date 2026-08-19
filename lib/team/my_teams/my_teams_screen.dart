import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/shared/app_search_field.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';
import '../utils/team_ui.dart';

class MyTeamsScreen extends HookWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');

    useEffect(() {
      void listener() {
        searchText.value = searchController.text;
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 350), () {
        debouncedSearch.value = searchText.value.trim();
      });
      return timer.cancel;
    }, [searchText.value]);

    final search = debouncedSearch.value;

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

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('My Teams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create team',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              controller: searchController,
              hintText: 'Search by team name',
              onCleared: () {
                searchText.value = '';
                debouncedSearch.value = '';
              },
            ),
          ),
          Expanded(child: _buildBody(query, memberships, search)),
        ],
      ),
    );
  }

  Widget _buildBody(
    InfiniteQueryResult<PaginatedResponse<TeamMemberModel>, Object, int> query,
    List<TeamMemberModel> memberships,
    String search,
  ) {
    if (query.isLoading || (query.isFetching && memberships.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && memberships.isEmpty) {
      return Center(
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
      );
    }

    if (memberships.isEmpty) {
      return _EmptyState(hasSearch: search.isNotEmpty);
    }

    return RefreshIndicator(
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            for (var i = 0; i < memberships.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _TeamCard(membership: memberships[i]),
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
        ),
      ),
    );
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
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
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
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
    );
  }
}
