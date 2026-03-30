import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import 'common/json_converters.dart';
import 'common/user_field_instance.dart';

part 'turf_model.g.dart';

@JsonSerializable()
class CoordinatesModel {
  final double? lat;
  final double? lng;

  CoordinatesModel({this.lat, this.lng});

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoordinatesModelToJson(this);

  CoordinatesModel copyWith({double? lat, double? lng}) {
    return CoordinatesModel(lat: lat ?? this.lat, lng: lng ?? this.lng);
  }

  @override
  String toString() {
    return 'CoordinatesModel(lat: $lat, lng: $lng)';
  }
}

@JsonSerializable()
class LocationModel {
  final String address;
  final CoordinatesModel coordinates;

  LocationModel({required this.address, required this.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);

  LocationModel copyWith({String? address, CoordinatesModel? coordinates}) {
    return LocationModel(
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  @override
  String toString() {
    return 'LocationModel(address: $address, coordinates: $coordinates)';
  }
}

@JsonSerializable()
class DimensionsModel {
  final double? length;
  final double? width;
  final String unit;

  DimensionsModel({this.length, this.width, required this.unit});

  factory DimensionsModel.fromJson(Map<String, dynamic> json) =>
      _$DimensionsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DimensionsModelToJson(this);

  DimensionsModel copyWith({double? length, double? width, String? unit}) {
    return DimensionsModel(
      length: length ?? this.length,
      width: width ?? this.width,
      unit: unit ?? this.unit,
    );
  }

  // Helper getter for area calculation
  double? get area {
    if (length != null && width != null) {
      return length! * width!;
    }
    return null;
  }

  @override
  String toString() {
    return 'DimensionsModel(length: $length, width: $width, unit: $unit)';
  }
}

@JsonSerializable()
class PricingModel {
  @JsonKey(name: 'basePricePerHour')
  final double basePricePerHour;
  @JsonKey(name: 'weekendSurge')
  final double weekendSurge;

  PricingModel({required this.basePricePerHour, required this.weekendSurge});

  factory PricingModel.fromJson(Map<String, dynamic> json) =>
      _$PricingModelFromJson(json);

  Map<String, dynamic> toJson() => _$PricingModelToJson(this);

  PricingModel copyWith({double? basePricePerHour, double? weekendSurge}) {
    return PricingModel(
      basePricePerHour: basePricePerHour ?? this.basePricePerHour,
      weekendSurge: weekendSurge ?? this.weekendSurge,
    );
  }

  // Helper getter for weekend price calculation
  double get weekendPricePerHour => basePricePerHour * (1 + weekendSurge);

  @override
  String toString() {
    return 'PricingModel(basePricePerHour: $basePricePerHour, weekendSurge: $weekendSurge)';
  }
}

@JsonSerializable()
class OperatingHoursModel {
  final String open;
  final String close;

  OperatingHoursModel({required this.open, required this.close});

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) =>
      _$OperatingHoursModelFromJson(json);

  Map<String, dynamic> toJson() => _$OperatingHoursModelToJson(this);

  OperatingHoursModel copyWith({String? open, String? close}) {
    return OperatingHoursModel(
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }

  // Helper getter for time parsing
  DateTime? parseTime(String time, DateTime date) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Helper method to check if currently open
  bool isCurrentlyOpen() {
    final now = DateTime.now();
    final openTime = parseTime(open, now);
    final closeTime = parseTime(close, now);

    if (openTime != null && closeTime != null) {
      return now.isAfter(openTime) && now.isBefore(closeTime);
    }
    return false;
  }

  @override
  String toString() {
    return 'OperatingHoursModel(open: $open, close: $close)';
  }
}

@JsonSerializable()
class TurfModel {
  @JsonKey(name: '_id')
  final String? id;
  @JsonKey(name: 'postedBy')
  @UserConverter()
  final dynamic postedBy; // Can be String (ID) or UserModel (populated)
  final String? name;
  final String? description;
  final LocationModel? location;
  final List<String>? images;
  final List<String>? amenities;
  final DimensionsModel? dimensions;
  @JsonKey(name: 'sportType')
  final List<String>? sportType;
  final PricingModel? pricing;
  @JsonKey(name: 'operatingHours')
  final OperatingHoursModel? operatingHours;
  @JsonKey(name: 'isAvailable')
  final bool? isAvailable;
  @JsonKey(name: 'slotBufferMins')
  final int? slotBufferMins;
  @JsonKey(name: 'averageRating')
  final double? averageRating;
  @JsonKey(name: 'totalReviews')
  final int? totalReviews;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  TurfModel({
    this.id,
    this.postedBy,
    this.name,
    this.description,
    this.location,
    this.images,
    this.amenities,
    this.dimensions,
    this.sportType,
    this.pricing,
    this.operatingHours,
    this.isAvailable,
    this.slotBufferMins,
    this.averageRating,
    this.totalReviews,
    this.createdAt,
    this.updatedAt,
  });

  factory TurfModel.fromJson(Map<String, dynamic> json) =>
      _$TurfModelFromJson(json);

  Map<String, dynamic> toJson() => _$TurfModelToJson(this);

  TurfModel copyWith({
    String? id,
    UserModel? postedBy,
    String? name,
    String? description,
    LocationModel? location,
    List<String>? images,
    List<String>? amenities,
    DimensionsModel? dimensions,
    List<String>? sportType,
    PricingModel? pricing,
    OperatingHoursModel? operatingHours,
    bool? isAvailable,
    int? slotBufferMins,
    double? averageRating,
    int? totalReviews,
    String? createdAt,
    String? updatedAt,
  }) {
    return TurfModel(
      id: id ?? this.id,
      postedBy: postedBy ?? this.postedBy,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      dimensions: dimensions ?? this.dimensions,
      sportType: sportType ?? this.sportType,
      pricing: pricing ?? this.pricing,
      operatingHours: operatingHours ?? this.operatingHours,
      isAvailable: isAvailable ?? this.isAvailable,
      slotBufferMins: slotBufferMins ?? this.slotBufferMins,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getter for display name with fallback
  String get displayName => name ?? 'Unnamed Turf';

  // Helper getter for sport types as formatted string
  String get sportTypesDisplay => sportType?.join(', ') ?? 'Not specified';

  // Helper getter for amenities as formatted string
  String get amenitiesDisplay => amenities?.join(', ') ?? 'None listed';

  // Helper getters for created date parsing
  DateTime? get createdAtDate {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (e) {
      return null;
    }
  }

  // Cached helper instance for posted by user information
  UserFieldInstance? _postedByHelper;
  UserFieldInstance get postedByHelper {
    _postedByHelper ??= UserFieldInstance(postedBy);
    return _postedByHelper!;
  }

  // Helper getter for updated date parsing
  DateTime? get updatedAtDate {
    if (updatedAt == null) return null;
    try {
      return DateTime.parse(updatedAt!);
    } catch (e) {
      return null;
    }
  }

  // Helper getter for rating display
  String get ratingDisplay {
    if (averageRating != null) {
      return '${averageRating!.toStringAsFixed(1)} (${totalReviews ?? 0} reviews)';
    }
    return 'No ratings yet';
  }

  // Helper getter for availability status
  String get availabilityStatus {
    if (isAvailable == true) {
      if (operatingHours?.isCurrentlyOpen() == true) {
        return 'Open Now';
      } else {
        return 'Available (Closed)';
      }
    }
    return 'Not Available';
  }

  // Helper getter for main image

  String? get mainImage => images?.isNotEmpty == true ? images!.first : null;

  @override
  String toString() {
    return 'TurfModel(id: $id, name: $name, location: ${location?.address})';
  }
}

// Request/Response models for API operations

@JsonSerializable()
class CreateTurfRequest {
  final String name;
  final String description;
  final LocationModel location;
  final List<String>? images;
  final List<String>? amenities;
  final DimensionsModel dimensions;
  @JsonKey(name: 'sportType')
  final List<String> sportType;
  final PricingModel pricing;
  @JsonKey(name: 'operatingHours')
  final OperatingHoursModel operatingHours;
  @JsonKey(name: 'slotBufferMins')
  final int? slotBufferMins;

  CreateTurfRequest({
    required this.name,
    required this.description,
    required this.location,
    this.images,
    this.amenities,
    required this.dimensions,
    required this.sportType,
    required this.pricing,
    required this.operatingHours,
    this.slotBufferMins,
  });

  factory CreateTurfRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTurfRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTurfRequestToJson(this);
}

@JsonSerializable()
class UpdateTurfRequest {
  final String? name;
  final String? description;
  final LocationModel? location;
  final List<String>? images;
  final List<String>? amenities;
  final DimensionsModel? dimensions;
  @JsonKey(name: 'sportType')
  final List<String>? sportType;
  final PricingModel? pricing;
  @JsonKey(name: 'operatingHours')
  final OperatingHoursModel? operatingHours;
  @JsonKey(name: 'isAvailable')
  final bool? isAvailable;
  @JsonKey(name: 'slotBufferMins')
  final int? slotBufferMins;

  UpdateTurfRequest({
    this.name,
    this.description,
    this.location,
    this.images,
    this.amenities,
    this.dimensions,
    this.sportType,
    this.pricing,
    this.operatingHours,
    this.isAvailable,
    this.slotBufferMins,
  });

  factory UpdateTurfRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTurfRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTurfRequestToJson(this);
}

// @JsonSerializable()
// class TurfSearchRequest {
//   final String? query;
//   final List<String>? sportType;
//   final double? minPrice;
//   final double? maxPrice;
//   final LocationModel? location;
//   final double? radius; // in kilometers
//   final bool? isAvailable;

//   TurfSearchRequest({
//     this.query,
//     this.sportType,
//     this.minPrice,
//     this.maxPrice,
//     this.location,
//     this.radius,
//     this.isAvailable,
//   });

//   factory TurfSearchRequest.fromJson(Map<String, dynamic> json) =>
//       _$TurfSearchRequestFromJson(json);

//   Map<String, dynamic> toJson() => _$TurfSearchRequestToJson(this);
// }
