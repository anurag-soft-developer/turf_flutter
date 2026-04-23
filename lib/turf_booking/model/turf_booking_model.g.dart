// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf_booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSlot _$TimeSlotFromJson(Map<String, dynamic> json) => TimeSlot(
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
);

Map<String, dynamic> _$TimeSlotToJson(TimeSlot instance) => <String, dynamic>{
  'startTime': instance.startTime,
  'endTime': instance.endTime,
};

TurfBookingModel _$TurfBookingModelFromJson(Map<String, dynamic> json) =>
    TurfBookingModel(
      id: json['_id'] as String?,
      turf: const TurfConverter().fromJson(json['turf']),
      bookedBy: const UserConverter().fromJson(json['bookedBy']),
      timeSlots: (json['timeSlots'] as List<dynamic>?)
          ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      playerCount: (json['playerCount'] as num?)?.toInt(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      status: $enumDecodeNullable(_$TurfBookingStatusEnumMap, json['status']),
      paymentStatus: $enumDecodeNullable(
        _$PaymentStatusEnumMap,
        json['paymentStatus'],
      ),
      paymentId: json['paymentId'] as String?,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      invoiceId: json['invoiceId'] as String?,
      paidAt: json['paidAt'] as String?,
      paymentExpiresAt: json['paymentExpiresAt'] as String?,
      slotHoldStatus: $enumDecodeNullable(
        _$SlotHoldStatusEnumMap,
        json['slotHoldStatus'],
      ),
      refundId: json['refundId'] as String?,
      refundedAt: json['refundedAt'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      cancelReason: json['cancelReason'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      confirmedAt: json['confirmedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$TurfBookingModelToJson(TurfBookingModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'turf': const TurfConverter().toJson(instance.turf),
      'bookedBy': const UserConverter().toJson(instance.bookedBy),
      'timeSlots': instance.timeSlots,
      'playerCount': instance.playerCount,
      'totalAmount': instance.totalAmount,
      'status': _$TurfBookingStatusEnumMap[instance.status],
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus],
      'paymentId': instance.paymentId,
      'razorpayOrderId': instance.razorpayOrderId,
      'invoiceId': instance.invoiceId,
      'paidAt': instance.paidAt,
      'paymentExpiresAt': instance.paymentExpiresAt,
      'slotHoldStatus': _$SlotHoldStatusEnumMap[instance.slotHoldStatus],
      'refundId': instance.refundId,
      'refundedAt': instance.refundedAt,
      'refundAmount': instance.refundAmount,
      'notes': instance.notes,
      'cancelReason': instance.cancelReason,
      'cancelledAt': instance.cancelledAt,
      'confirmedAt': instance.confirmedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$TurfBookingStatusEnumMap = {
  TurfBookingStatus.pending: 'pending',
  TurfBookingStatus.confirmed: 'confirmed',
  TurfBookingStatus.cancelled: 'cancelled',
  TurfBookingStatus.completed: 'completed',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
};

const _$SlotHoldStatusEnumMap = {
  SlotHoldStatus.active: 'active',
  SlotHoldStatus.released: 'released',
};

CreateTurfBookingRequest _$CreateTurfBookingRequestFromJson(
  Map<String, dynamic> json,
) => CreateTurfBookingRequest(
  turf: json['turf'] as String,
  timeSlots: (json['timeSlots'] as List<dynamic>)
      .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  playerCount: (json['playerCount'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CreateTurfBookingRequestToJson(
  CreateTurfBookingRequest instance,
) => <String, dynamic>{
  'turf': instance.turf,
  'timeSlots': instance.timeSlots,
  'playerCount': instance.playerCount,
  'notes': instance.notes,
};

RazorpayOrderModel _$RazorpayOrderModelFromJson(Map<String, dynamic> json) =>
    RazorpayOrderModel(
      id: json['id'] as String,
      entity: json['entity'] as String,
      amount: (json['amount'] as num).toInt(),
      amountPaid: (json['amount_paid'] as num).toInt(),
      amountDue: (json['amount_due'] as num).toInt(),
      currency: json['currency'] as String,
      receipt: json['receipt'] as String,
      status: json['status'] as String,
      attempts: (json['attempts'] as num).toInt(),
      createdAt: (json['created_at'] as num).toInt(),
    );

Map<String, dynamic> _$RazorpayOrderModelToJson(RazorpayOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entity': instance.entity,
      'amount': instance.amount,
      'amount_paid': instance.amountPaid,
      'amount_due': instance.amountDue,
      'currency': instance.currency,
      'receipt': instance.receipt,
      'status': instance.status,
      'attempts': instance.attempts,
      'created_at': instance.createdAt,
    };

CreateBookingOrderResponse _$CreateBookingOrderResponseFromJson(
  Map<String, dynamic> json,
) => CreateBookingOrderResponse(
  booking: TurfBookingModel.fromJson(json['booking']),
  order: RazorpayOrderModel.fromJson(json['order'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateBookingOrderResponseToJson(
  CreateBookingOrderResponse instance,
) => <String, dynamic>{'booking': instance.booking, 'order': instance.order};

VerifyRazorpayPaymentRequest _$VerifyRazorpayPaymentRequestFromJson(
  Map<String, dynamic> json,
) => VerifyRazorpayPaymentRequest(
  bookingId: json['bookingId'] as String,
  razorpayOrderId: json['razorpay_order_id'] as String,
  razorpayPaymentId: json['razorpay_payment_id'] as String,
  razorpaySignature: json['razorpay_signature'] as String,
);

Map<String, dynamic> _$VerifyRazorpayPaymentRequestToJson(
  VerifyRazorpayPaymentRequest instance,
) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'razorpay_order_id': instance.razorpayOrderId,
  'razorpay_payment_id': instance.razorpayPaymentId,
  'razorpay_signature': instance.razorpaySignature,
};

UpdateTurfBookingRequest _$UpdateTurfBookingRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTurfBookingRequest(
  playerCount: (json['playerCount'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  status: $enumDecodeNullable(_$TurfBookingStatusEnumMap, json['status']),
  paymentStatus: $enumDecodeNullable(
    _$PaymentStatusEnumMap,
    json['paymentStatus'],
  ),
  paymentId: json['paymentId'] as String?,
  cancelReason: json['cancelReason'] as String?,
);

Map<String, dynamic> _$UpdateTurfBookingRequestToJson(
  UpdateTurfBookingRequest instance,
) => <String, dynamic>{
  'playerCount': instance.playerCount,
  'notes': instance.notes,
  'status': _$TurfBookingStatusEnumMap[instance.status],
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus],
  'paymentId': instance.paymentId,
  'cancelReason': instance.cancelReason,
};

TurfBookingFilterRequest _$TurfBookingFilterRequestFromJson(
  Map<String, dynamic> json,
) => TurfBookingFilterRequest(
  turf: json['turf'] as String?,
  bookedBy: json['bookedBy'] as String?,
  status: $enumDecodeNullable(_$TurfBookingStatusEnumMap, json['status']),
  paymentStatus: $enumDecodeNullable(
    _$PaymentStatusEnumMap,
    json['paymentStatus'],
  ),
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  page: (json['page'] as num?)?.toInt() ?? 1,
  limit: (json['limit'] as num?)?.toInt() ?? 10,
  sortBy: json['sortBy'] as String? ?? 'createdAt',
  sortOrder: json['sortOrder'] as String? ?? 'desc',
);

Map<String, dynamic> _$TurfBookingFilterRequestToJson(
  TurfBookingFilterRequest instance,
) => <String, dynamic>{
  'turf': instance.turf,
  'bookedBy': instance.bookedBy,
  'status': _$TurfBookingStatusEnumMap[instance.status],
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus],
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'page': instance.page,
  'limit': instance.limit,
  'sortBy': instance.sortBy,
  'sortOrder': instance.sortOrder,
};

CheckTurfAvailabilityRequest _$CheckTurfAvailabilityRequestFromJson(
  Map<String, dynamic> json,
) => CheckTurfAvailabilityRequest(
  turf: json['turf'] as String,
  timeSlots: (json['timeSlots'] as List<dynamic>)
      .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  excludeBookingId: json['excludeBookingId'] as String?,
);

Map<String, dynamic> _$CheckTurfAvailabilityRequestToJson(
  CheckTurfAvailabilityRequest instance,
) => <String, dynamic>{
  'turf': instance.turf,
  'timeSlots': instance.timeSlots,
  'excludeBookingId': instance.excludeBookingId,
};

TurfAvailabilityResponse _$TurfAvailabilityResponseFromJson(
  Map<String, dynamic> json,
) => TurfAvailabilityResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: AvailabilityData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TurfAvailabilityResponseToJson(
  TurfAvailabilityResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

AvailabilityData _$AvailabilityDataFromJson(Map<String, dynamic> json) =>
    AvailabilityData(isAvailable: json['isAvailable'] as bool);

Map<String, dynamic> _$AvailabilityDataToJson(AvailabilityData instance) =>
    <String, dynamic>{'isAvailable': instance.isAvailable};
