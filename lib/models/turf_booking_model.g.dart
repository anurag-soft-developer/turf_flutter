// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf_booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurfBookingModel _$TurfBookingModelFromJson(Map<String, dynamic> json) =>
    TurfBookingModel(
      id: json['_id'] as String?,
      turf: json['turf'] as String?,
      bookedBy: json['bookedBy'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      playerCount: (json['playerCount'] as num?)?.toInt(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      status: $enumDecodeNullable(_$TurfBookingStatusEnumMap, json['status']),
      paymentStatus: $enumDecodeNullable(
        _$PaymentStatusEnumMap,
        json['paymentStatus'],
      ),
      paymentId: json['paymentId'] as String?,
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
      'turf': instance.turf,
      'bookedBy': instance.bookedBy,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'playerCount': instance.playerCount,
      'totalAmount': instance.totalAmount,
      'status': _$TurfBookingStatusEnumMap[instance.status],
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus],
      'paymentId': instance.paymentId,
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

CreateTurfBookingRequest _$CreateTurfBookingRequestFromJson(
  Map<String, dynamic> json,
) => CreateTurfBookingRequest(
  turf: json['turf'] as String,
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  playerCount: (json['playerCount'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CreateTurfBookingRequestToJson(
  CreateTurfBookingRequest instance,
) => <String, dynamic>{
  'turf': instance.turf,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'playerCount': instance.playerCount,
  'notes': instance.notes,
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
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  excludeBookingId: json['excludeBookingId'] as String?,
);

Map<String, dynamic> _$CheckTurfAvailabilityRequestToJson(
  CheckTurfAvailabilityRequest instance,
) => <String, dynamic>{
  'turf': instance.turf,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
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
