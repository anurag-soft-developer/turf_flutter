import 'package:flutter/material.dart';
import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:get/get.dart';
import 'model/turf_booking_model.dart';
import 'turf_booking_controller.dart';
import '../components/shared/app_segmented_tabs.dart';
import '../components/booking/booking_action_dialogs.dart';
import '../components/booking/booking_card.dart';
import '../components/booking/qr_scanner_screen.dart';
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
  late int _lastHandledTabIndex;
  static const TurfBookingStatus? _allStatuses = null;
  final List<TurfBookingStatus?> _tabStatuses = [
    _allStatuses,
    ...TurfBookingStatus.values,
  ];

  @override
  void initState() {
    super.initState();
    _tabItems = const [
      AppTabItem(label: 'All'),
      AppTabItem(label: 'Pending'),
      AppTabItem(label: 'Confirmed'),
      AppTabItem(label: 'Cancelled'),
      AppTabItem(label: 'Completed'),
    ];
    _tabController = TabController(
      length: _tabItems.length,
      vsync: this,
      initialIndex: _getInitialTabIndex(),
    );
    _lastHandledTabIndex = _tabController.index;
    _tabController.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChanged);
    _tabController.dispose();
    super.dispose();
  }

  int _getInitialTabIndex() {
    final selectedFilters =
        TurfBookingController.instance.selectedStatusFilters;
    if (selectedFilters.length != 1) return 0;
    final selectedStatus = selectedFilters.first;
    final matchedIndex = _tabStatuses.indexOf(selectedStatus);
    return matchedIndex == -1 ? 0 : matchedIndex;
  }

  void _onStatusTabSelected(
    int index,
    TurfBookingController bookingController,
  ) {
    _lastHandledTabIndex = index;
    final selectedStatus = _tabStatuses[index];
    if (selectedStatus == null) {
      bookingController.clearFilters();
      return;
    }
    bookingController.applyFilters(status: selectedStatus);
  }

  void _onTabIndexChanged() {
    if (_tabController.indexIsChanging) return;
    if (_lastHandledTabIndex == _tabController.index) return;
    _lastHandledTabIndex = _tabController.index;
    _onStatusTabSelected(_tabController.index, TurfBookingController.instance);
  }

  @override
  Widget build(BuildContext context) {
    final bookingController = TurfBookingController.instance;
    final SettingsController setting = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Obx(
          () => Text(
            setting.isPlayerMode ? 'My Bookings' : "Turf Bookings",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Scanner button for proprietor mode
          if (setting.isProprietorMode)
            IconButton(
              onPressed: () => Get.to(() => const QRScannerScreen()),
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan QR Code',
            ),
        ],
      ),
      // drawer: const AppDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              AppSegmentedTabs(
                controller: _tabController,
                items: _tabItems,
                onTap: (index) =>
                    _onStatusTabSelected(index, bookingController),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              ),
              Expanded(
                child: AppSegmentedTabView(
                  controller: _tabController,
                  children: List.generate(
                    _tabItems.length,
                    (_) => Obx(() {
                      if (bookingController.bookings.isEmpty &&
                          !bookingController.isLoading.value) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book_online,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Bookings Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                setting.isPlayerMode
                                    ? 'You haven\'t made any turf bookings yet.\nStart by browsing available turfs.'
                                    : 'No customers have booked your turfs yet.\nMake sure your turfs are properly listed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            bookingController.loadBookings(refresh: true),
                        child: NotificationListener<ScrollNotification>(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                bookingController.bookings.length +
                                (bookingController.hasMoreData.value ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == bookingController.bookings.length) {
                                return Obx(
                                  () => bookingController.isLoading.value
                                      ? const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox(),
                                );
                              }

                              final booking = bookingController.bookings[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: BookingCard(
                                  booking: booking,
                                  isOwnerView: setting.isProprietorMode,
                                  onCancel:
                                      BookingActionDialogs.showCancelBooking,
                                  onComplete:
                                      BookingActionDialogs.showCompleteBooking,
                                  onConfirm:
                                      BookingActionDialogs.showConfirmBooking,
                                ),
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
}
