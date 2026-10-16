import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/pinned_sliver_header.dart';
import '../core/config/constants.dart';
import '../core/models/paginated_response.dart';
import '../core/query/query_keys.dart';
import '../core/query/query_retry.dart';
import '../core/utils/app_snackbar.dart';
import 'model/enrollment_model.dart';
import 'model/opening_model.dart';
import 'opening_service.dart';

/// Poster view of one opening's enrollments.
class OpeningRequestsScreen extends HookWidget {
  const OpeningRequestsScreen({super.key});

  static const _tabs = EnrollmentStatus.values;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final argOpeningId = args is Map && args['openingId'] is String
        ? (args['openingId'] as String).trim()
        : '';
    final teamId = args is Map && args['teamId'] is String
        ? (args['teamId'] as String).trim()
        : '';
    final titleArg = args is Map && args['title'] is String
        ? (args['title'] as String).trim()
        : '';

    final openingQuery = useQuery<OpeningModel?, Object>(
      ['openingByTeam', teamId],
      (_) => OpeningService().findByTarget(
        type: OpeningType.team,
        targetId: teamId,
      ),
      enabled: argOpeningId.isEmpty && teamId.isNotEmpty,
      retry: noRetry,
    );

    final openingId = argOpeningId.isNotEmpty
        ? argOpeningId
        : (openingQuery.data?.id ?? '');
    final title = titleArg.isNotEmpty
        ? titleArg
        : (openingQuery.data?.hostName ?? '');

    final selectedTab = useState(EnrollmentStatus.pending);
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

    final resolving =
        argOpeningId.isEmpty &&
        teamId.isNotEmpty &&
        (openingQuery.isLoading || openingQuery.isFetching) &&
        openingId.isEmpty;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FloatingSliverAppBar(
              title: Text(title.isEmpty ? 'Requests' : 'Requests · $title'),
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
        body: resolving
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(AppColors.primaryColor),
                  ),
                ),
              )
            : openingId.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'This team has no opening to review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            : AppSegmentedTabView(
                controller: tabController,
                children: [
                  for (final tab in _tabs)
                    _EnrollmentTab(
                      key: ValueKey('$openingId-${tab.name}'),
                      openingId: openingId,
                      status: tab,
                    ),
                ],
              ),
      ),
    );
  }
}

class _EnrollmentTab extends HookWidget {
  const _EnrollmentTab({
    super.key,
    required this.openingId,
    required this.status,
  });

  final String openingId;
  final EnrollmentStatus status;

  @override
  Widget build(BuildContext context) {
    final busyId = useState<String?>(null);
    final query =
        useInfiniteQuery<PaginatedResponse<EnrollmentModel>, Object, int>(
          QueryKeys.openingEnrollments(openingId, status.name),
          (ctx) async {
            final result = await OpeningService().enrollmentsForOpening(
              openingId,
              EnrollmentListQuery(status: status, page: ctx.pageParam, limit: 20),
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

    Future<void> decide(EnrollmentModel row, {required bool accept}) async {
      final id = row.id;
      if (id == null || id.isEmpty || busyId.value != null) return;
      busyId.value = id;
      final result = accept
          ? await OpeningService().accept(openingId, id)
          : await OpeningService().reject(openingId, id);
      busyId.value = null;
      if (result == null) return;
      AppSnackbar.success(
        title: accept ? 'Accepted' : 'Rejected',
        message: accept
            ? 'The enrollment was accepted.'
            : 'The enrollment was rejected.',
      );
      if (!Get.isRegistered<QueryClient>()) return;
      final client = Get.find<QueryClient>();
      await Future.wait([
        client.invalidateQueries(
          queryKey: QueryKeys.openingEnrollmentsPrefix(openingId),
        ),
        client.invalidateQueries(queryKey: QueryKeys.myEnrollmentsPrefix),
        if (row.subjectType == 'team' && (row.teamId ?? '').isNotEmpty)
          client.invalidateQueries(queryKey: ['teamRoster', row.teamId]),
      ]);
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
            const Text(
              'Failed to load requests',
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

    if (items.isEmpty) {
      return Center(
        child: Text(
          switch (status) {
            EnrollmentStatus.pending => 'No pending requests.',
            EnrollmentStatus.accepted => 'No accepted requests.',
            EnrollmentStatus.rejected => 'No rejected requests.',
          },
          style: const TextStyle(
            color: Color(AppColors.textSecondaryColor),
            fontSize: 15,
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
              _RequestRow(
                enrollment: items[i],
                busy: busyId.value == items[i].id,
                onAccept: status == EnrollmentStatus.pending
                    ? () => decide(items[i], accept: true)
                    : null,
                onReject: status == EnrollmentStatus.pending
                    ? () => decide(items[i], accept: false)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.enrollment,
    required this.busy,
    this.onAccept,
    this.onReject,
  });

  final EnrollmentModel enrollment;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final name = enrollment.isTournament
        ? (enrollment.teamName ?? 'Team')
        : (enrollment.userName ?? 'Player');
    final image = enrollment.isTournament
        ? enrollment.teamLogo
        : enrollment.userAvatar;
    final subtitle = enrollment.isTournament
        ? (enrollment.userName ?? 'Tournament entry')
        : null;

    return Card(
      elevation: 0,
      color: const Color(AppColors.surfaceColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            Row(
              children: [
                _Avatar(name: name, image: image),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (onAccept != null || onReject != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onAccept,
                      child: Text(busy ? 'Saving…' : 'Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.image});

  final String name;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: image != null && image!.isNotEmpty
          ? AppNetworkImage(image!, fit: BoxFit.cover)
          : Center(
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(AppColors.primaryColor),
                ),
              ),
            ),
    );
  }
}
