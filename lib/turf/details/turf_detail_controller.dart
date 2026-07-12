import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/config/env_config.dart';
import 'package:flutter_application_1/turf_booking/model/turf_booking_model.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/query/query_keys.dart';
import '../../turf_booking/model/turf_booking_model.dart' as booking_model;
import '../../turf_booking/turf_booking_service.dart';
import '../model/turf_model.dart';

/// UI + Razorpay booking state. Turf/slots fetching is owned by flutter_query.
class TurfDetailController extends GetxController {
  static TurfDetailController get instance => Get.find();

  final TurfBookingService _bookingService = TurfBookingService();
  late final Razorpay _razorpay;

  final RxBool _isBookingLoading = false.obs;
  final Rxn<TurfModel> _turf = Rxn<TurfModel>();
  final RxList<TurfTimeSlotListing> _selectedTimeSlots =
      <TurfTimeSlotListing>[].obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;
  final RxInt _currentImageIndex = 0.obs;
  final RxDouble _totalPrice = 0.0.obs;

  RxBool get isBookingLoading => _isBookingLoading;
  Rxn<TurfModel> get turf => _turf;
  RxList<TurfTimeSlotListing> get selectedTimeSlots => _selectedTimeSlots;
  Rx<DateTime> get selectedDate => _selectedDate;
  RxInt get currentImageIndex => _currentImageIndex;
  RxDouble get totalPrice => _totalPrice;

  String? _turfId;
  String? _pendingBookingId;
  String? _pendingOrderId;

  String? get turfId => _turfId;

  static final _dateKeyFormat = DateFormat('yyyy-MM-dd');

  String get selectedDateKey => _dateKeyFormat.format(_selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();

    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      _turfId = arguments['turfId'] as String?;
    }
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void syncTurf(TurfModel? turf) {
    _turf.value = turf;
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _openRazorpayCheckout({
    required RazorpayOrderModel order,
    required TurfBookingModel booking,
  }) {
    final key = EnvConfig.razorpayKeyId;
    if (key.isEmpty) {
      Get.snackbar(
        'Payment Setup Missing',
        'Razorpay key is not configured. Please add RAZORPAY_KEY_ID to .env',
      );
      return;
    }

    _pendingBookingId = booking.id;
    _pendingOrderId = order.id;

    final options = {
      'key': key,
      'amount': order.amount,
      'order_id': order.id,
      'name': EnvConfig.appName.isNotEmpty ? EnvConfig.appName : 'Play App',
      'description': 'Turf booking payment',
      'currency': order.currency,
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#00835A'},
    };

    _razorpay.open(options);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingId == null) {
      Get.snackbar(
        'Payment Error',
        'Booking reference missing for verification.',
      );
      return;
    }

    _isBookingLoading.value = true;
    try {
      final verifiedBooking = await _bookingService.verifyBookingPayment(
        VerifyRazorpayPaymentRequest(
          bookingId: _pendingBookingId!,
          razorpayOrderId: response.orderId ?? _pendingOrderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        ),
      );

      if (verifiedBooking != null) {
        _selectedTimeSlots.clear();
        _totalPrice.value = 0.0;
        _pendingBookingId = null;
        _pendingOrderId = null;
        await _invalidateAfterBooking();
        Get.toNamed(
          AppConstants.routes.bookingTicket,
          arguments: {
            'bookingId': verifiedBooking.id ?? verifiedBooking.bookingId,
            'booking': verifiedBooking,
          },
        );
        return;
      }

      Get.snackbar(
        'Verification Failed',
        'Payment captured but booking verification failed. Please contact support.',
      );
    } catch (e) {
      Get.snackbar(
        'Verification Failed',
        'Could not verify payment. Please check My Bookings.',
      );
    } finally {
      _isBookingLoading.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = response.message?.isNotEmpty == true
        ? response.message!
        : 'Payment was not completed.';
    Get.snackbar('Payment Failed', message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final walletName = response.walletName ?? 'external wallet';
    Get.snackbar(
      'External Wallet Selected',
      'Complete payment using $walletName to continue.',
    );
  }

  void toggleTimeSlot(TurfTimeSlotListing slot) {
    if (!slot.isAvailable) return;

    if (_selectedTimeSlots.contains(slot)) {
      _selectedTimeSlots.remove(slot);
    } else {
      _selectedTimeSlots.add(slot);
    }

    _selectedTimeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (final slot in _selectedTimeSlots) {
      total += slot.price;
    }
    _totalPrice.value = total;
  }

  static const int maxBookingDaysAhead = 30;

  DateTime get minSelectableDate {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  DateTime get maxSelectableDate =>
      minSelectableDate.add(const Duration(days: maxBookingDaysAhead));

  void changeSelectedDate(DateTime date) {
    final selectedDateOnly = DateTime(date.year, date.month, date.day);

    if (selectedDateOnly.isBefore(minSelectableDate)) {
      Get.snackbar('Invalid Date', 'Cannot select past dates');
      return;
    }

    if (selectedDateOnly.isAfter(maxSelectableDate)) {
      Get.snackbar(
        'Invalid Date',
        'Bookings are only available up to $maxBookingDaysAhead days ahead',
      );
      return;
    }

    _selectedDate.value = selectedDateOnly;
    _selectedTimeSlots.clear();
    _totalPrice.value = 0.0;
  }

  void changeImageIndex(int index) {
    _currentImageIndex.value = index;
  }

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
      final apiTimeSlots = _selectedTimeSlots.map((slot) {
        return booking_model.TimeSlot(
          startTime: slot.startTime,
          endTime: slot.endTime,
        );
      }).toList();

      final isAvailable = await _bookingService.checkTimeSlotsAvailability(
        CheckTurfAvailabilityRequest(turf: _turfId!, timeSlots: apiTimeSlots),
      );

      if (!isAvailable) {
        Get.snackbar(
          'Slots Unavailable',
          'Some selected time slots are no longer available. Please refresh and try again.',
        );
        await _invalidateSlots();
        return;
      }

      final bookingOrder = await _bookingService.createBookingOrder(
        CreateTurfBookingRequest(turf: _turfId!, timeSlots: apiTimeSlots),
      );

      if (bookingOrder != null) {
        _openRazorpayCheckout(
          order: bookingOrder.order,
          booking: bookingOrder.booking,
        );
      } else {
        Get.snackbar(
          'Order Creation Failed',
          'Failed to create booking order. Please try again.',
        );
      }
    } catch (e) {
      Get.snackbar('Booking Failed', 'An error occurred: ${e.toString()}');
    } finally {
      _isBookingLoading.value = false;
    }
  }

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

  bool get isCurrentlyOpen {
    return turf.value?.operatingHours?.isCurrentlyOpen() ?? false;
  }

  String get locationInfo {
    return turf.value?.location?.address ?? 'Location not available';
  }

  Future<void> refreshData() async {
    await _invalidateTurfAndSlots();
    final id = _turfId;
    if (id == null || !Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(queryKey: ['turfReviews', id]),
      client.invalidateQueries(queryKey: QueryKeys.turfReviewStats(id)),
    ]);
  }

  Future<void> _invalidateAfterBooking() async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: const ['bookings']),
    ];
    final id = _turfId;
    if (id != null) {
      futures.add(
        client.invalidateQueries(
          queryKey: QueryKeys.turfSlots(id, selectedDateKey),
        ),
      );
    }
    await Future.wait(futures);
  }

  Future<void> _invalidateSlots() async {
    final id = _turfId;
    if (id == null || !Get.isRegistered<QueryClient>()) return;
    await Get.find<QueryClient>().invalidateQueries(
      queryKey: QueryKeys.turfSlots(id, selectedDateKey),
    );
  }

  Future<void> _invalidateTurfAndSlots() async {
    final id = _turfId;
    if (id == null || !Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await Future.wait([
      client.invalidateQueries(queryKey: QueryKeys.turfDetail(id)),
      client.invalidateQueries(queryKey: QueryKeys.turfSlots(id, selectedDateKey)),
    ]);
  }
}
