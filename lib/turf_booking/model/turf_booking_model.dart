import 'package:json_annotation/json_annotation.dart';
import '../../turf/model/turf_model.dart';
import '../../core/models/turf_field_converter.dart';
import '../../core/models/user_field_converters.dart';
import '../../core/models/user_field_instance.dart';
import '../../core/models/turf_field_instance.dart';

part 'turf_booking_model.g.dart';

// TimeSlot model for individual time slots
@JsonSerializable()
class TimeSlot {
  @JsonKey(name: 'startTime')
  final String startTime;
  @JsonKey(name: 'endTime')
  final String endTime;

  TimeSlot({required this.startTime, required this.endTime});

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);

  // Helper getters
  DateTime? get startDateTime {
    try {
      return DateTime.parse(startTime);
    } catch (e) {
      return null;
    }
  }

  DateTime? get endDateTime {
    try {
      return DateTime.parse(endTime);
    } catch (e) {
      return null;
    }
  }

  Duration? get duration {
    final start = startDateTime;
    final end = endDateTime;
    if (start != null && end != null) {
      return end.difference(start);
    }
    return null;
  }

  String get timeDisplay {
    final start = startDateTime;
    final end = endDateTime;
    if (start != null && end != null) {
      final startTime =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endTime =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      return '$startTime - $endTime';
    }
    return 'Time not available';
  }

  TimeSlot copyWith({String? startTime, String? endTime}) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() {
    return 'TimeSlot(startTime: $startTime, endTime: $endTime)';
  }
}

/// Response item from `GET /turf/:turfId/time-slots`.
class TurfTimeSlotListing {
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final double price;
  final bool isBooked;

  TurfTimeSlotListing({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.price,
    required this.isBooked,
  });

  factory TurfTimeSlotListing.fromJson(Map<String, dynamic> json) {
    return TurfTimeSlotListing(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isAvailable: json['isAvailable'] as bool,
      price: (json['price'] as num).toDouble(),
      isBooked: json['isBooked'] as bool,
    );
  }

  String get timeDisplay {
    return '${DateTime.parse(startTime).hour.toString().padLeft(2, '0')}:${DateTime.parse(startTime).minute.toString().padLeft(2, '0')} - ${DateTime.parse(endTime).hour.toString().padLeft(2, '0')}:${DateTime.parse(endTime).minute.toString().padLeft(2, '0')}';
  }
}

// Enums
enum TurfBookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('completed')
  completed,
}

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}

// Main Model
@JsonSerializable()
class TurfBookingModel {
  @JsonKey(name: '_id')
  final String? id;
  @TurfConverter()
  final dynamic turf; // Can be String (ID) or TurfModel (populated)
  @JsonKey(name: 'bookedBy')
  @UserConverter()
  final dynamic bookedBy; // Can be String (ID) or UserModel (populated)
  @JsonKey(name: 'timeSlots')
  final List<TimeSlot>? timeSlots;
  @JsonKey(name: 'playerCount')
  final int? playerCount;
  @JsonKey(name: 'totalAmount')
  final double? totalAmount;
  final TurfBookingStatus? status;
  @JsonKey(name: 'paymentStatus')
  final PaymentStatus? paymentStatus;
  @JsonKey(name: 'paymentId')
  final String? paymentId;
  final String? notes;
  @JsonKey(name: 'cancelReason')
  final String? cancelReason;
  @JsonKey(name: 'cancelledAt')
  final String? cancelledAt;
  @JsonKey(name: 'confirmedAt')
  final String? confirmedAt;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  TurfBookingModel({
    this.id,
    this.turf,
    this.bookedBy,
    this.timeSlots,
    this.playerCount,
    this.totalAmount,
    this.status,
    this.paymentStatus,
    this.paymentId,
    this.notes,
    this.cancelReason,
    this.cancelledAt,
    this.confirmedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TurfBookingModel.fromJson(dynamic json) =>
      _$TurfBookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$TurfBookingModelToJson(this);

  TurfBookingModel copyWith({
    String? id,
    dynamic turf,
    dynamic bookedBy,
    List<TimeSlot>? timeSlots,
    int? playerCount,
    double? totalAmount,
    TurfBookingStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentId,
    String? notes,
    String? cancelReason,
    String? cancelledAt,
    String? confirmedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return TurfBookingModel(
      id: id ?? this.id,
      turf: turf ?? this.turf,
      bookedBy: bookedBy ?? this.bookedBy,
      timeSlots: timeSlots ?? this.timeSlots,
      playerCount: playerCount ?? this.playerCount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Cached helper instances for dynamic fields
  TurfFieldInstance? _turfHelper;
  TurfFieldInstance get turfHelper {
    _turfHelper ??= TurfFieldInstance(turf);
    return _turfHelper!;
  }

  UserFieldInstance? _bookedByHelper;
  UserFieldInstance get bookedByHelper {
    _bookedByHelper ??= UserFieldInstance(bookedBy);
    return _bookedByHelper!;
  }

  // Legacy helper getters for backward compatibility
  String? get turfId => turfHelper.getId();
  TurfModel? get turfModel => turfHelper.getModel();
  String get turfDisplayName => turfHelper.getDisplayName();

  // Helper getters for time slots
  DateTime? get firstStartDateTime {
    if (timeSlots != null && timeSlots!.isNotEmpty) {
      return timeSlots!.first.startDateTime;
    }
    return null;
  }

  DateTime? get lastEndDateTime {
    if (timeSlots != null && timeSlots!.isNotEmpty) {
      return timeSlots!.last.endDateTime;
    }
    return null;
  }

  // Backward compatibility getters
  DateTime? get startDateTime => firstStartDateTime;
  DateTime? get endDateTime => lastEndDateTime;

  DateTime? get cancelledDateTime {
    if (cancelledAt != null) {
      try {
        return DateTime.parse(cancelledAt!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  DateTime? get confirmedDateTime {
    if (confirmedAt != null) {
      try {
        return DateTime.parse(confirmedAt!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  DateTime? get createdDateTime {
    if (createdAt != null) {
      try {
        return DateTime.parse(createdAt!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Duration getter - total duration across all time slots
  Duration? get bookingDuration {
    if (timeSlots == null || timeSlots!.isEmpty) return null;

    Duration totalDuration = Duration.zero;
    for (final slot in timeSlots!) {
      final slotDuration = slot.duration;
      if (slotDuration != null) {
        totalDuration += slotDuration;
      }
    }
    return totalDuration.inMinutes > 0 ? totalDuration : null;
  }

  // Get total slots count
  int get slotsCount => timeSlots?.length ?? 0;

  // Status helper getters
  bool get isPending => status == TurfBookingStatus.pending;
  bool get isConfirmed => status == TurfBookingStatus.confirmed;
  bool get isCancelled => status == TurfBookingStatus.cancelled;
  bool get isCompleted => status == TurfBookingStatus.completed;

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isPaymentPending => paymentStatus == PaymentStatus.pending;
  bool get isPaymentFailed => paymentStatus == PaymentStatus.failed;
  bool get isRefunded => paymentStatus == PaymentStatus.refunded;

  // Display formatters
  String get statusDisplay {
    switch (status) {
      case TurfBookingStatus.pending:
        return 'Pending';
      case TurfBookingStatus.confirmed:
        return 'Confirmed';
      case TurfBookingStatus.cancelled:
        return 'Cancelled';
      case TurfBookingStatus.completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  String get bookingTimeDisplay {
    if (timeSlots == null || timeSlots!.isEmpty) {
      return 'Time not available';
    }

    if (timeSlots!.length == 1) {
      return timeSlots!.first.timeDisplay;
    }

    // Multiple time slots - show first to last
    final firstSlot = timeSlots!.first;
    final lastSlot = timeSlots!.last;
    final firstStart = firstSlot.startDateTime;
    final lastEnd = lastSlot.endDateTime;

    if (firstStart != null && lastEnd != null) {
      final startTime =
          '${firstStart.hour.toString().padLeft(2, '0')}:${firstStart.minute.toString().padLeft(2, '0')}';
      final endTime =
          '${lastEnd.hour.toString().padLeft(2, '0')}:${lastEnd.minute.toString().padLeft(2, '0')}';
      return '$startTime - $endTime (${timeSlots!.length} slots)';
    }

    return 'Multiple time slots';
  }

  // Get all time slots as display strings
  List<String> get timeSlotsDisplay {
    if (timeSlots == null) return [];
    return timeSlots!.map((slot) => slot.timeDisplay).toList();
  }

  @override
  String toString() {
    return 'TurfBookingModel(id: $id, turfId: $turfId, status: $status)';
  }
}

// Request/Response models for API operations

@JsonSerializable()
class CreateTurfBookingRequest {
  final String turf;
  @JsonKey(name: 'timeSlots')
  final List<TimeSlot> timeSlots;
  @JsonKey(name: 'playerCount')
  final int? playerCount;
  final String? notes;

  CreateTurfBookingRequest({
    required this.turf,
    required this.timeSlots,
    this.playerCount,
    this.notes,
  });

  factory CreateTurfBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTurfBookingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTurfBookingRequestToJson(this);
}

@JsonSerializable()
class UpdateTurfBookingRequest {
  @JsonKey(name: 'playerCount')
  final int? playerCount;
  final String? notes;
  final TurfBookingStatus? status;
  @JsonKey(name: 'paymentStatus')
  final PaymentStatus? paymentStatus;
  @JsonKey(name: 'paymentId')
  final String? paymentId;
  @JsonKey(name: 'cancelReason')
  final String? cancelReason;

  UpdateTurfBookingRequest({
    this.playerCount,
    this.notes,
    this.status,
    this.paymentStatus,
    this.paymentId,
    this.cancelReason,
  });

  factory UpdateTurfBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTurfBookingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTurfBookingRequestToJson(this);
}

@JsonSerializable()
class TurfBookingFilterRequest {
  final String? turf;
  @JsonKey(name: 'bookedBy')
  final String? bookedBy;
  final TurfBookingStatus? status;
  @JsonKey(name: 'paymentStatus')
  final PaymentStatus? paymentStatus;
  @JsonKey(name: 'startDate')
  final String? startDate;
  @JsonKey(name: 'endDate')
  final String? endDate;
  final int? page;
  final int? limit;
  @JsonKey(name: 'sortBy')
  final String? sortBy;
  @JsonKey(name: 'sortOrder')
  final String? sortOrder;

  TurfBookingFilterRequest({
    this.turf,
    this.bookedBy,
    this.status,
    this.paymentStatus,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 10,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  factory TurfBookingFilterRequest.fromJson(Map<String, dynamic> json) =>
      _$TurfBookingFilterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TurfBookingFilterRequestToJson(this);
}

@JsonSerializable()
class CheckTurfAvailabilityRequest {
  final String turf;
  @JsonKey(name: 'timeSlots')
  final List<TimeSlot> timeSlots;
  @JsonKey(name: 'excludeBookingId')
  final String? excludeBookingId;

  CheckTurfAvailabilityRequest({
    required this.turf,
    required this.timeSlots,
    this.excludeBookingId,
  });

  factory CheckTurfAvailabilityRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckTurfAvailabilityRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckTurfAvailabilityRequestToJson(this);
}

@JsonSerializable()
class TurfAvailabilityResponse {
  final bool success;
  final String message;
  final AvailabilityData data;

  TurfAvailabilityResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TurfAvailabilityResponse.fromJson(Map<String, dynamic> json) =>
      _$TurfAvailabilityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TurfAvailabilityResponseToJson(this);
}

@JsonSerializable()
class AvailabilityData {
  @JsonKey(name: 'isAvailable')
  final bool isAvailable;

  AvailabilityData({required this.isAvailable});

  factory AvailabilityData.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityDataFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityDataToJson(this);
}
