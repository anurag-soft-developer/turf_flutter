import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/components/bottom_navigation_panel/navigation_controller.dart';
import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/components/scroll/pinned_sliver_header.dart';
import '../../core/config/constants.dart';
import '../../explore/model/explore_category.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/utils/app_snackbar.dart';
import '../../openings/model/enrollment_model.dart';
import '../../openings/model/opening_model.dart';
import '../../openings/opening_service.dart';
import '../../team/model/team_model.dart';
import '../../team/utils/team_ui.dart';

enum JoinRequestStatusTab { pending, accepted, rejected }

void _openExplorePosts() {
  Get.back();
  Get.find<NavigationController>().goToExplore(
    category: ExploreCategory.post,
  );
}

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
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FloatingSliverAppBar(
              title: const Text('My requests'),
              actions: [
                IconButton(
                  tooltip: 'Openings',
                  icon: const Icon(Icons.search),
                  onPressed: _openExplorePosts,
                ),
              ],
            ),
            PinnedSliverHeader(
              child: AppSegmentedTabs(
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
                  AppTabItem(label: 'Accepted', icon: Icons.check_circle_outline),
                  AppTabItem(label: 'Rejected', icon: Icons.cancel_outlined),
                ],
              ),
            ),
          ];
        },
        body: AppSegmentedTabView(
          controller: tabController,
          children: [
            for (final tab in _tabs)
              _RequestTabList(key: ValueKey(tab.name), tab: tab),
          ],
        ),
      ),
    );
  }
}

class _RequestTabList extends HookWidget {
  const _RequestTabList({super.key, required this.tab});

  final JoinRequestStatusTab tab;

  EnrollmentStatus get _status => switch (tab) {
    JoinRequestStatusTab.pending => EnrollmentStatus.pending,
    JoinRequestStatusTab.accepted => EnrollmentStatus.accepted,
    JoinRequestStatusTab.rejected => EnrollmentStatus.rejected,
  };

  @override
  Widget build(BuildContext context) {
    final withdrawingId = useState<String?>(null);
    final query =
        useInfiniteQuery<PaginatedResponse<EnrollmentModel>, Object, int>(
          QueryKeys.myEnrollments(tab.name),
          (ctx) async {
            final result = await OpeningService().myEnrollments(
              EnrollmentListQuery(
                status: _status,
                page: ctx.pageParam,
                limit: 20,
              ),
            );
            return result ?? EmptyPaginatedResponse<EnrollmentModel>();
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
        const <EnrollmentModel>[];

    Future<void> withdraw(EnrollmentModel row) async {
      if (row.openingId.isEmpty || withdrawingId.value != null) return;
      withdrawingId.value = row.id ?? row.openingId;
      final ok = await OpeningService().withdraw(
        row.openingId,
        teamId: row.isTournament ? row.teamId : null,
      );
      withdrawingId.value = null;
      if (!ok) return;
      AppSnackbar.success(
        title: 'Withdrawn',
        message: 'Your enrollment was withdrawn.',
      );
      if (!Get.isRegistered<QueryClient>()) return;
      await Get.find<QueryClient>().invalidateQueries(
        queryKey: QueryKeys.myEnrollmentsPrefix,
      );
    }

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
              'Failed to load your requests',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _emptyMessage(tab),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _openExplorePosts,
                child: const Text('Browse openings'),
              ),
            ],
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
              _EnrollmentRow(
                enrollment: items[i],
                withdrawing: withdrawingId.value == (items[i].id ?? items[i].openingId),
                onWithdraw: tab == JoinRequestStatusTab.pending
                    ? () => withdraw(items[i])
                    : null,
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
        ),
      ),
    );
  }

  String _emptyMessage(JoinRequestStatusTab t) {
    return switch (t) {
      JoinRequestStatusTab.pending => 'No pending requests.',
      JoinRequestStatusTab.accepted => 'No accepted requests.',
      JoinRequestStatusTab.rejected => 'No rejected requests.',
    };
  }
}

class _EnrollmentRow extends StatelessWidget {
  const _EnrollmentRow({
    required this.enrollment,
    required this.withdrawing,
    this.onWithdraw,
  });

  final EnrollmentModel enrollment;
  final bool withdrawing;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final sport = _sportOf(enrollment.sportType);
    final subtitle = [
      if (enrollment.isTournament && (enrollment.teamName ?? '').isNotEmpty)
        enrollment.teamName!,
      if (sport != null) teamSportLabel(sport),
      if (enrollment.title.isNotEmpty) enrollment.title,
    ].join(' · ');

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: _openHost,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: enrollment.hostImage != null && enrollment.hostImage!.isNotEmpty
              ? AppNetworkImage(
                  enrollment.hostImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initials(enrollment.hostName),
                )
              : _initials(enrollment.hostName),
        ),
        title: Text(
          enrollment.hostName.isEmpty ? 'Opening' : enrollment.hostName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
        trailing: onWithdraw == null
            ? null
            : TextButton(
                onPressed: withdrawing ? null : onWithdraw,
                child: Text(withdrawing ? '…' : 'Withdraw'),
              ),
      ),
    );
  }

  void _openHost() {
    if (enrollment.subjectType == OpeningType.team.apiValue) {
      if (enrollment.hostId.isEmpty) return;
      Get.toNamed(
        AppConstants.routes.teamProfile,
        arguments: {'teamId': enrollment.hostId},
      );
      return;
    }
    if (enrollment.hostId.isEmpty) return;
    Get.toNamed(AppConstants.routes.tournamentDetail(enrollment.hostId));
  }

  static Widget _initials(String name) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(AppColors.primaryColor),
        ),
      ),
    );
  }
}

TeamSportType? _sportOf(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final sport in TeamSportType.values) {
    if (sport.name == raw) return sport;
  }
  return null;
}
