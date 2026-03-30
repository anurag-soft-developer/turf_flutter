import 'package:get/get.dart';
import '../models/turf_model.dart';
import '../services/turf_service.dart';
import '../controllers/turf_booking_controller.dart';
import '../models/turf_booking_model.dart' as booking_model;

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final double price;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.price,
  });

  String get timeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMin = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
  }
}

class TurfDetailController extends GetxController {
  static TurfDetailController get instance => Get.find();

  final TurfService _turfService = TurfService();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isBookingLoading = false.obs;
  final Rxn<TurfModel> _turf = Rxn<TurfModel>();
  final RxList<TimeSlot> _timeSlots = <TimeSlot>[].obs;
  final RxList<TimeSlot> _selectedTimeSlots = <TimeSlot>[].obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;
  final RxInt _currentImageIndex = 0.obs;
  final RxDouble _totalPrice = 0.0.obs;

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isBookingLoading => _isBookingLoading;
  Rxn<TurfModel> get turf => _turf;
  RxList<TimeSlot> get timeSlots => _timeSlots;
  RxList<TimeSlot> get selectedTimeSlots => _selectedTimeSlots;
  Rx<DateTime> get selectedDate => _selectedDate;
  RxInt get currentImageIndex => _currentImageIndex;
  RxDouble get totalPrice => _totalPrice;

  String? _turfId;

  @override
  void onInit() {
    super.onInit();

    // Get turf ID from arguments
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      _turfId = arguments['turfId'];
      if (_turfId != null) {
        loadTurfDetails();
        // Don't call generateTimeSlots here - will be called after turf loads
      }
    }
  }

  // Load turf details
  Future<void> loadTurfDetails() async {
    if (_turfId == null) return;

    _isLoading.value = true;

    try {
      final turfs = await _turfService.getTurfById(_turfId!);
      if (turfs != null) {
        _turf.value = turfs;
        // Generate time slots after turf data is loaded
        generateTimeSlots();
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

  // Generate time slots based on operating hours
  void generateTimeSlots() {
    _timeSlots.clear();
    _selectedTimeSlots.clear();
    _totalPrice.value = 0.0;

    final currentTurf = _turf.value;
    if (currentTurf?.operatingHours == null || currentTurf?.pricing == null)
      return;

    final operatingHours = currentTurf!.operatingHours!;
    final pricing = currentTurf.pricing!;
    final selectedDateTime = _selectedDate.value;

    // Parse operating hours
    final openTime = operatingHours.parseTime(
      operatingHours.open,
      selectedDateTime,
    );
    final closeTime = operatingHours.parseTime(
      operatingHours.close,
      selectedDateTime,
    );

    if (openTime == null || closeTime == null) return;

    // Generate hourly slots
    DateTime currentSlotStart = openTime;
    while (currentSlotStart.isBefore(closeTime)) {
      final slotEnd = currentSlotStart.add(const Duration(hours: 1));
      if (slotEnd.isAfter(closeTime)) break;

      // Check if slot is in the past for today
      final now = DateTime.now();
      final isToday =
          selectedDateTime.year == now.year &&
          selectedDateTime.month == now.month &&
          selectedDateTime.day == now.day;
      final isPastSlot = isToday && currentSlotStart.isBefore(now);

      // Calculate price (include weekend surge if applicable)
      final isWeekend =
          selectedDateTime.weekday == DateTime.saturday ||
          selectedDateTime.weekday == DateTime.sunday;
      final slotPrice = isWeekend
          ? pricing.weekendPricePerHour
          : pricing.basePricePerHour;

      final timeSlot = TimeSlot(
        startTime: currentSlotStart,
        endTime: slotEnd,
        isAvailable: !isPastSlot && (currentTurf.isAvailable ?? false),
        price: slotPrice,
      );

      _timeSlots.add(timeSlot);
      currentSlotStart = slotEnd;
    }
  }

  // Select/deselect time slot
  void toggleTimeSlot(TimeSlot slot) {
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
    generateTimeSlots();
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
        // Ensure the DateTime is in local timezone before converting to ISO with timezone
        final localStartTime = slot.startTime.toLocal();
        final localEndTime = slot.endTime.toLocal();

        // Use toIso8601String() to include timezone information
        final startTimeString = localStartTime.toIso8601String();
        final endTimeString = localEndTime.toIso8601String();

        return booking_model.TimeSlot(
          startTime: startTimeString,
          endTime: endTimeString,
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
        generateTimeSlots();
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
        '${firstSlot.startTime.hour.toString().padLeft(2, '0')}:${firstSlot.startTime.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${lastSlot.endTime.hour.toString().padLeft(2, '0')}:${lastSlot.endTime.minute.toString().padLeft(2, '0')}';

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
    generateTimeSlots();
  }
}
