import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'turf_booking_controller.dart';
import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../components/booking/booking_card.dart';
import '../core/config/constants.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<AppTabItem> _tabItems;
  final List<BookingsTab> _tabs = BookingsTab.values;

  @override
  void initState() {
    super.initState();
    _tabItems = const [
      AppTabItem(label: 'Upcoming'),
      AppTabItem(label: 'Pending'),
      AppTabItem(label: 'Archive'),
    ];
    _tabController = TabController(
      length: _tabItems.length,
      vsync: this,
      initialIndex: _getInitialTabIndex(),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;
      if (idx >= 0 && idx < _tabs.length) {
        TurfBookingController.instance.switchTab(_tabs[idx]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getInitialTabIndex() {
    final selectedTab = TurfBookingController.instance.selectedTab.value;
    final matchedIndex = _tabs.indexOf(selectedTab);
    return matchedIndex == -1 ? 0 : matchedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final bookingController = TurfBookingController.instance;

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
      body: Stack(
        children: [
          Column(
            children: [
              AppSegmentedTabs(
                controller: _tabController,
                items: _tabItems,
                fillWidth: true,
                onTap: (index) => bookingController.switchTab(_tabs[index]),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              ),
              Expanded(
                child: AppSegmentedTabView(
                  controller: _tabController,
                  children: List.generate(
                    _tabItems.length,
                    (index) => Obx(() {
                      final tab = _tabs[index];
                      final state = bookingController.tabStateFor(tab);
                      final bookings = state.items;
                      final isFirstLoad =
                          !state.hasInitialized && bookings.isEmpty;

                      if (isFirstLoad ||
                          (state.isFetching && bookings.isEmpty)) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(AppColors.primaryColor),
                            ),
                          ),
                        );
                      }

                      if (state.error != null && bookings.isEmpty) {
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
                              Text(
                                state.error!,
                                style: const TextStyle(
                                  color: Color(AppColors.textSecondaryColor),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => bookingController
                                    .ensureTabLoaded(tab, force: true),
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
                              const Icon(
                                Icons.book_online,
                                size: 64,
                                color: Colors.grey,
                              ),
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
                        onRefresh: () =>
                            bookingController.ensureTabLoaded(tab, force: true),
                        color: const Color(AppColors.primaryColor),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.pixels >=
                                notification.metrics.maxScrollExtent - 200) {
                              bookingController.loadMore(tab);
                            }
                            return false;
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                bookings.length + (state.isLoadingMore ? 1 : 0),
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
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
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
