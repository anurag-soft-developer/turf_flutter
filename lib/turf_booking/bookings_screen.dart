import 'package:flutter/material.dart';
import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:get/get.dart';
import 'model/turf_booking_model.dart';
import 'turf_booking_controller.dart';
import '../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
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
  final List<TurfBookingStatus?> _tabStatuses = [null, ...TurfBookingStatus.values];

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
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final idx = _tabController.index;
      if (idx >= 0 && idx < _tabStatuses.length) {
        TurfBookingController.instance.switchStatusTab(_tabStatuses[idx]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getInitialTabIndex() {
    final selectedStatus = TurfBookingController.instance.selectedStatusTab.value;
    final matchedIndex = _tabStatuses.indexOf(selectedStatus);
    return matchedIndex == -1 ? 0 : matchedIndex;
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
                    bookingController.switchStatusTab(_tabStatuses[index]),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              ),
              Expanded(
                child: AppSegmentedTabView(
                  controller: _tabController,
                  children: List.generate(
                    _tabItems.length,
                    (index) => Obx(() {
                      final status = _tabStatuses[index];
                      final state = bookingController.tabStateFor(status);
                      final bookings = state.items;
                      final isFirstLoad = !state.hasInitialized && bookings.isEmpty;

                      if (isFirstLoad || (state.isFetching && bookings.isEmpty)) {
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
                                onPressed: () =>
                                    bookingController.ensureTabLoaded(status, force: true),
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
                            bookingController.ensureTabLoaded(status, force: true),
                        child: NotificationListener<ScrollNotification>(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
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
