import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../members/model/team_member_model.dart';
import '../team_service.dart';
import '../utils/team_ui.dart';

enum JoinRequestStatusTab { pending, accepted, rejected }

class MyJoinRequestsScreen extends HookWidget {
  const MyJoinRequestsScreen({super.key});

  static const _tabs = JoinRequestStatusTab.values;

  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(JoinRequestStatusTab.pending);
    final ticker = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(
        length: _tabs.length,
        vsync: ticker,
        initialIndex: _tabs.indexOf(selectedTab.value),
      ),
      [ticker],
    );

    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) return;
        final i = tabController.index;
        if (i >= 0 && i < _tabs.length) {
          selectedTab.value = _tabs[i];
        }
      }

      tabController.addListener(listener);
      return () {
        tabController.removeListener(listener);
        tabController.dispose();
      };
    }, [tabController]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Join requests'),
        actions: [
          IconButton(
            tooltip: 'Find teams',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed(AppConstants.routes.teamOpenings),
          ),
        ],
      ),
      body: Column(
        children: [
          AppSegmentedTabs(
            controller: tabController,
            fillWidth: true,
            onTap: (index) {
              selectedTab.value = _tabs[index];
              tabController.animateTo(index);
            },
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            items: const [
              AppTabItem(
                label: 'Pending',
                icon: Icons.hourglass_top_outlined,
              ),
              AppTabItem(label: 'Joined', icon: Icons.check_circle_outline),
              AppTabItem(label: 'Rejected', icon: Icons.cancel_outlined),
            ],
          ),
          Expanded(
            child: AppSegmentedTabView(
              controller: tabController,
              children: [
                for (final tab in _tabs)
                  _RequestTabList(key: ValueKey(tab.name), tab: tab),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTabList extends HookWidget {
  const _RequestTabList({super.key, required this.tab});

  final JoinRequestStatusTab tab;

  TeamMemberStatus get _status => switch (tab) {
        JoinRequestStatusTab.pending => TeamMemberStatus.pending,
        JoinRequestStatusTab.accepted => TeamMemberStatus.active,
        JoinRequestStatusTab.rejected => TeamMemberStatus.rejected,
      };

  @override
  Widget build(BuildContext context) {
    final query =
        useInfiniteQuery<PaginatedResponse<TeamMemberModel>, Object, int>(
      QueryKeys.myJoinRequests(tab.name),
      (ctx) async {
        final result = await TeamService().memberService.myMemberships(
          MyTeamMembershipsFilterQuery(
            status: _status,
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

    final items =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <TeamMemberModel>[];

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
              'Failed to load your join requests',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _emptyMessage(tab),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 15,
            ),
          ),
        ),
      );
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _MembershipRow(membership: items[i]),
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

  String _emptyMessage(JoinRequestStatusTab t) {
    return switch (t) {
      JoinRequestStatusTab.pending => 'No pending join requests.',
      JoinRequestStatusTab.accepted =>
        'No active team memberships in this list.',
      JoinRequestStatusTab.rejected => 'No rejected join requests.',
    };
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({required this.membership});

  final TeamMemberModel membership;

  @override
  Widget build(BuildContext context) {
    final teamRef = membership.team;
    String teamName = 'Team';
    String? logo;
    TeamSportType? sport;
    String? teamId = membership.teamId;

    if (teamRef is TeamMemberFieldInstance) {
      teamName = teamRef.name;
      logo = teamRef.logo.isNotEmpty ? teamRef.logo : null;
      sport = teamRef.sportType;
    }

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: teamId == null || teamId.isEmpty
            ? null
            : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': teamId},
              ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: logo != null
              ? Image.network(
                  logo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initials(teamName),
                )
              : _initials(teamName),
        ),
        title: Text(
          teamName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        subtitle: sport != null
            ? Text(
                teamSportLabel(sport),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(membership.status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            teamMemberStatusLabel(membership.status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _statusColor(membership.status),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final s = parts.isEmpty
        ? '?'
        : (parts.length == 1
              ? (parts[0].isNotEmpty ? parts[0][0] : '?')
              : '${parts[0][0]}${parts[1][0]}');
    return Center(
      child: Text(
        s.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }

  Color _statusColor(TeamMemberStatus s) {
    return switch (s) {
      TeamMemberStatus.pending => const Color(0xFFF9A825),
      TeamMemberStatus.active => const Color(0xFF2E7D32),
      TeamMemberStatus.rejected => const Color(0xFFC62828),
      _ => const Color(AppColors.textSecondaryColor),
    };
  }
}
