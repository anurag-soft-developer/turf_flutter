import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../components/booking/booking_card.dart';
import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../core/config/constants.dart';
import '../core/models/paginated_response.dart';
import '../core/query/query_keys.dart';
import 'model/turf_booking_model.dart';
import 'turf_booking_controller.dart';
import 'turf_booking_service.dart';

Duration? _noRetry(int count, Object error) => null;

class BookingsScreen extends HookWidget {
  const BookingsScreen({super.key});

  static const _tabItems = [
    AppTabItem(label: 'Upcoming'),
    AppTabItem(label: 'Pending'),
    AppTabItem(label: 'Archive'),
  ];

  static const _tabs = BookingsTab.values;

  @override
  Widget build(BuildContext context) {
    final bookingController = TurfBookingController.instance;
    final ticker = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(
        length: _tabItems.length,
        vsync: ticker,
        initialIndex: () {
          final matched = _tabs.indexOf(bookingController.selectedTab.value);
          return matched == -1 ? 0 : matched;
        }(),
      ),
      [ticker],
    );

    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) return;
        final idx = tabController.index;
        if (idx >= 0 && idx < _tabs.length) {
          bookingController.switchTab(_tabs[idx]);
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
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          AppSegmentedTabs(
            controller: tabController,
            items: _tabItems,
            fillWidth: true,
            onTap: (index) => bookingController.switchTab(_tabs[index]),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          ),
          Expanded(
            child: Obx(() {
              final paymentFilter =
                  bookingController.paymentStatusFilter.value?.name;
              return AppSegmentedTabView(
                controller: tabController,
                children: [
                  for (final tab in _tabs)
                    _BookingsTabPane(
                      key: ValueKey('${tab.name}|${paymentFilter ?? ''}'),
                      tab: tab,
                      paymentStatusFilter:
                          bookingController.paymentStatusFilter.value,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BookingsTabPane extends HookWidget {
  const _BookingsTabPane({
    super.key,
    required this.tab,
    this.paymentStatusFilter,
  });

  final BookingsTab tab;
  final PaymentStatus? paymentStatusFilter;

  @override
  Widget build(BuildContext context) {
    final queryKey = QueryKeys.bookings(
      tab: tab.name,
      paymentStatus: paymentStatusFilter?.name,
    );

    final query =
        useInfiniteQuery<PaginatedResponse<TurfBookingModel>, Object, int>(
      queryKey,
      (ctx) async {
        final statuses = switch (tab) {
          BookingsTab.upcoming => const [TurfBookingStatus.confirmed],
          BookingsTab.pending => const [TurfBookingStatus.pending],
          BookingsTab.archive => null,
        };
        final upcoming = switch (tab) {
          BookingsTab.upcoming => true,
          BookingsTab.pending => true,
          BookingsTab.archive => false,
        };
        final sortBy = tab == BookingsTab.archive ? 'updatedAt' : 'createdAt';
        final sortOrder = tab == BookingsTab.archive ? 'desc' : 'asc';

        final response = await TurfBookingService().findBookings(
          page: ctx.pageParam,
          limit: 20,
          status: statuses,
          upcoming: upcoming,
          paymentStatus: paymentStatusFilter,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
        return response ?? EmptyPaginatedResponse<TurfBookingModel>();
      },
      initialPageParam: 1,
      retry: _noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final bookings =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <TurfBookingModel>[];

    if (query.isLoading || (query.isFetching && bookings.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load bookings',
              style: TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 15,
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

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_online, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _emptyTitleFor(tab),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emptySubtitleFor(tab),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => query.refetch(),
      color: const Color(AppColors.primaryColor),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            if (query.hasNextPage && !query.isFetchingNextPage) {
              query.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length + (query.isFetchingNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == bookings.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              );
            }
            final booking = bookings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BookingCard(booking: booking),
            );
          },
        ),
      ),
    );
  }

  String _emptyTitleFor(BookingsTab tab) {
    switch (tab) {
      case BookingsTab.upcoming:
        return 'No Upcoming Bookings';
      case BookingsTab.pending:
        return 'No Pending Bookings';
      case BookingsTab.archive:
        return 'Nothing Archived';
    }
  }

  String _emptySubtitleFor(BookingsTab tab) {
    switch (tab) {
      case BookingsTab.upcoming:
        return 'Confirmed bookings with future time slots will appear here.';
      case BookingsTab.pending:
        return 'Pending bookings with upcoming time slots will appear here.';
      case BookingsTab.archive:
        return 'Past, completed, and cancelled bookings will appear here.';
    }
  }
}
