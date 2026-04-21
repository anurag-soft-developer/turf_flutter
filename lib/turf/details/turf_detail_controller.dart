import 'package:flutter/material.dart';
import 'package:flutter_application_1/turf_booking/model/turf_booking_model.dart';
import 'package:get/get.dart';
import '../model/turf_model.dart';
import '../turf_service.dart';
import '../reviews/turf_reviews_list_controller.dart';
import '../../turf_booking/turf_booking_controller.dart';
import '../../turf_booking/turf_booking_service.dart';
import '../../turf_booking/model/turf_booking_model.dart' as booking_model;

class TurfDetailController extends GetxController {
  static TurfDetailController get instance => Get.find();

  final TurfService _turfService = TurfService();
  final TurfBookingService _bookingService = TurfBookingService();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isSlotsLoading = false.obs;
  final RxBool _isBookingLoading = false.obs;
  final Rxn<TurfModel> _turf = Rxn<TurfModel>();
  final RxList<TurfTimeSlotListing> _timeSlots = <TurfTimeSlotListing>[].obs;
  final RxList<TurfTimeSlotListing> _selectedTimeSlots =
      <TurfTimeSlotListing>[].obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;
  final RxInt _currentImageIndex = 0.obs;
  final RxDouble _totalPrice = 0.0.obs;

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isSlotsLoading => _isSlotsLoading;
  RxBool get isBookingLoading => _isBookingLoading;
  Rxn<TurfModel> get turf => _turf;
  RxList<TurfTimeSlotListing> get timeSlots => _timeSlots;
  RxList<TurfTimeSlotListing> get selectedTimeSlots => _selectedTimeSlots;
  Rx<DateTime> get selectedDate => _selectedDate;
  RxInt get currentImageIndex => _currentImageIndex;
  RxDouble get totalPrice => _totalPrice;

  String? _turfId;

  String? get turfId => _turfId;

  @override
  void onInit() {
    super.onInit();

    // Get turf ID from arguments
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      _turfId = arguments['turfId'] as String?;
      if (_turfId != null) {
        Get.put(
          TurfReviewsListController(
            turfId: _turfId!,
            previewOnly: true,
            previewLimit: 3,
          ),
          tag: turfReviewsPreviewTag(_turfId!),
        );
        loadTurfDetails();
      }
    }
  }

  @override
  void onClose() {
    final id = _turfId;
    if (id != null &&
        Get.isRegistered<TurfReviewsListController>(
          tag: turfReviewsPreviewTag(id),
        )) {
      Get.delete<TurfReviewsListController>(tag: turfReviewsPreviewTag(id));
    }
    super.onClose();
  }

  // Load turf details
  Future<void> loadTurfDetails() async {
    if (_turfId == null) return;

    _isLoading.value = true;

    try {
      final turfs = await _turfService.getTurfById(_turfId!);
      if (turfs != null) {
        _turf.value = turfs;
        await loadTimeSlots();
      } else {
        Get.snackbar('Error', 'Turf not found');
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load turf details');
      Get.back();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadTimeSlots() async {
    if (_turfId == null) return;

    _timeSlots.clear();
    _selectedTimeSlots.clear();
    _totalPrice.value = 0.0;

    _isSlotsLoading.value = true;

    final tempDate = _selectedDate.value;

    try {
      final listings = await _bookingService.getTimeSlotsForDate(
        _turfId!,
        tempDate,
      );

      if (tempDate != _selectedDate.value) {
        debugPrint(
          'Date changed, ignoring time slots ${_selectedDate.value} $tempDate',
        );
        return;
      }
      _timeSlots.assignAll(listings);
    } finally {
      _isSlotsLoading.value = false;
    }
  }

  // Select/deselect time slot
  void toggleTimeSlot(TurfTimeSlotListing slot) {
    if (!slot.isAvailable) return;

    if (_selectedTimeSlots.contains(slot)) {
      _selectedTimeSlots.remove(slot);
    } else {
      _selectedTimeSlots.add(slot);
    }

    // Sort selected slots by time
    _selectedTimeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate total price
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (final slot in _selectedTimeSlots) {
      total += slot.price;
    }
    _totalPrice.value = total;
  }

  // Change selected date
  void changeSelectedDate(DateTime date) {
    // Don't allow past dates
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(date.year, date.month, date.day);

    if (selectedDateOnly.isBefore(todayDate)) {
      Get.snackbar('Invalid Date', 'Cannot select past dates');
      return;
    }

    _selectedDate.value = date;
    loadTimeSlots();
  }

  // Change image index for carousel
  void changeImageIndex(int index) {
    _currentImageIndex.value = index;
  }

  // Book selected time slots
  Future<void> bookTimeSlots() async {
    if (_selectedTimeSlots.isEmpty) {
      Get.snackbar(
        'Selection Required',
        'Please select at least one time slot',
      );
      return;
    }

    if (_turfId == null) {
      Get.snackbar('Error', 'Turf ID not found');
      return;
    }

    _isBookingLoading.value = true;

    try {
      // Convert selected time slots to API format
      final apiTimeSlots = _selectedTimeSlots.map((slot) {
        return booking_model.TimeSlot(
          startTime: slot.startTime,
          endTime: slot.endTime,
        );
      }).toList();

      // Get or initialize the booking controller
      TurfBookingController bookingController;
      try {
        bookingController = Get.find<TurfBookingController>();
      } catch (e) {
        // If not found, put it manually
        bookingController = Get.put(TurfBookingController());
      }

      // Optional: Check availability before booking
      final isAvailable = await bookingController.checkTimeSlotsAvailability(
        turfId: _turfId!,
        timeSlots: apiTimeSlots,
      );

      if (!isAvailable) {
        Get.snackbar(
          'Slots Unavailable',
          'Some selected time slots are no longer available. Please refresh and try again.',
        );
        // Refresh time slots to get updated availability
        loadTimeSlots();
        return;
      }

      // Create the booking
      final booking = await bookingController.createBooking(
        turfId: _turfId!,
        timeSlots: apiTimeSlots,
        // playerCount: null, // You can add a player count field if needed
        // notes: null, // You can add a notes field if needed
      );

      if (booking != null) {
        Get.snackbar(
          'Booking Successful',
          'Your turf has been booked for ${_selectedTimeSlots.length} slot(s)',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Clear selections
        _selectedTimeSlots.clear();
        _totalPrice.value = 0.0;

        // Navigate back or to booking confirmation screen
        Get.back();
      } else {
        Get.snackbar(
          'Booking Failed',
          'Failed to create booking. Please try again.',
        );
      }
    } catch (e) {
      Get.snackbar('Booking Failed', 'An error occurred: ${e.toString()}');
    } finally {
      _isBookingLoading.value = false;
    }
  }

  // Get formatted booking summary
  String get bookingSummary {
    if (_selectedTimeSlots.isEmpty) return 'No slots selected';

    final firstSlot = _selectedTimeSlots.first;
    final lastSlot = _selectedTimeSlots.last;

    final startTime =
        '${DateTime.parse(firstSlot.startTime).hour.toString().padLeft(2, '0')}:${DateTime.parse(firstSlot.startTime).minute.toString().padLeft(2, '0')}';
    final endTime =
        '${DateTime.parse(lastSlot.endTime).hour.toString().padLeft(2, '0')}:${DateTime.parse(lastSlot.endTime).minute.toString().padLeft(2, '0')}';

    return '$startTime - $endTime (${_selectedTimeSlots.length} slot${_selectedTimeSlots.length > 1 ? 's' : ''})';
  }

  // Get next 7 days for date selection
  List<DateTime> get availableDates {
    final List<DateTime> dates = [];
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      dates.add(DateTime(today.year, today.month, today.day + i));
    }

    return dates;
  }

  // Check if turf is currently open
  bool get isCurrentlyOpen {
    return turf.value?.operatingHours?.isCurrentlyOpen() ?? false;
  }

  // Get distance or location info (placeholder for future implementation)
  String get locationInfo {
    return turf.value?.location?.address ?? 'Location not available';
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadTurfDetails();
    final id = _turfId;
    if (id != null &&
        Get.isRegistered<TurfReviewsListController>(
          tag: turfReviewsPreviewTag(id),
        )) {
      await Get.find<TurfReviewsListController>(
        tag: turfReviewsPreviewTag(id),
      ).reload();
    }
  }
}
