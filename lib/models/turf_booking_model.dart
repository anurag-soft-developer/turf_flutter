import 'package:json_annotation/json_annotation.dart';

part 'turf_booking_model.g.dart';

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
  final String? turf;
  @JsonKey(name: 'bookedBy')
  final String? bookedBy;
  @JsonKey(name: 'startTime')
  final String? startTime;
  @JsonKey(name: 'endTime')
  final String? endTime;
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
    this.startTime,
    this.endTime,
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

  factory TurfBookingModel.fromJson(Map<String, dynamic> json) =>
      _$TurfBookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$TurfBookingModelToJson(this);

  TurfBookingModel copyWith({
    String? id,
    String? turf,
    String? bookedBy,
    String? startTime,
    String? endTime,
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
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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

  // Helper getters
  DateTime? get startDateTime {
    if (startTime != null) {
      try {
        return DateTime.parse(startTime!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  DateTime? get endDateTime {
    if (endTime != null) {
      try {
        return DateTime.parse(endTime!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

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

  // Duration getter
  Duration? get bookingDuration {
    final start = startDateTime;
    final end = endDateTime;
    if (start != null && end != null) {
      return end.difference(start);
    }
    return null;
  }

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

  @override
  String toString() {
    return 'TurfBookingModel(id: $id, turf: $turf, status: $status)';
  }
}

// Request/Response models for API operations

@JsonSerializable()
class CreateTurfBookingRequest {
  final String turf;
  @JsonKey(name: 'startTime')
  final String startTime;
  @JsonKey(name: 'endTime')
  final String endTime;
  @JsonKey(name: 'playerCount')
  final int? playerCount;
  final String? notes;

  CreateTurfBookingRequest({
    required this.turf,
    required this.startTime,
    required this.endTime,
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
  @JsonKey(name: 'startTime')
  final String startTime;
  @JsonKey(name: 'endTime')
  final String endTime;
  @JsonKey(name: 'excludeBookingId')
  final String? excludeBookingId;

  CheckTurfAvailabilityRequest({
    required this.turf,
    required this.startTime,
    required this.endTime,
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
