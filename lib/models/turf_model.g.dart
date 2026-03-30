// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoordinatesModel _$CoordinatesModelFromJson(Map<String, dynamic> json) =>
    CoordinatesModel(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CoordinatesModelToJson(CoordinatesModel instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      address: json['address'] as String,
      coordinates: CoordinatesModel.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'coordinates': instance.coordinates,
    };

DimensionsModel _$DimensionsModelFromJson(Map<String, dynamic> json) =>
    DimensionsModel(
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$DimensionsModelToJson(DimensionsModel instance) =>
    <String, dynamic>{
      'length': instance.length,
      'width': instance.width,
      'unit': instance.unit,
    };

PricingModel _$PricingModelFromJson(Map<String, dynamic> json) => PricingModel(
  basePricePerHour: (json['basePricePerHour'] as num).toDouble(),
  weekendSurge: (json['weekendSurge'] as num).toDouble(),
);

Map<String, dynamic> _$PricingModelToJson(PricingModel instance) =>
    <String, dynamic>{
      'basePricePerHour': instance.basePricePerHour,
      'weekendSurge': instance.weekendSurge,
    };

OperatingHoursModel _$OperatingHoursModelFromJson(Map<String, dynamic> json) =>
    OperatingHoursModel(
      open: json['open'] as String,
      close: json['close'] as String,
    );

Map<String, dynamic> _$OperatingHoursModelToJson(
  OperatingHoursModel instance,
) => <String, dynamic>{'open': instance.open, 'close': instance.close};

TurfModel _$TurfModelFromJson(Map<String, dynamic> json) => TurfModel(
  id: json['_id'] as String?,
  postedBy: const UserConverter().fromJson(json['postedBy']),
  name: json['name'] as String?,
  description: json['description'] as String?,
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  amenities: (json['amenities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  dimensions: json['dimensions'] == null
      ? null
      : DimensionsModel.fromJson(json['dimensions'] as Map<String, dynamic>),
  sportType: (json['sportType'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pricing: json['pricing'] == null
      ? null
      : PricingModel.fromJson(json['pricing'] as Map<String, dynamic>),
  operatingHours: json['operatingHours'] == null
      ? null
      : OperatingHoursModel.fromJson(
          json['operatingHours'] as Map<String, dynamic>,
        ),
  isAvailable: json['isAvailable'] as bool?,
  slotBufferMins: (json['slotBufferMins'] as num?)?.toInt(),
  averageRating: (json['averageRating'] as num?)?.toDouble(),
  totalReviews: (json['totalReviews'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$TurfModelToJson(TurfModel instance) => <String, dynamic>{
  '_id': instance.id,
  'postedBy': const UserConverter().toJson(instance.postedBy),
  'name': instance.name,
  'description': instance.description,
  'location': instance.location,
  'images': instance.images,
  'amenities': instance.amenities,
  'dimensions': instance.dimensions,
  'sportType': instance.sportType,
  'pricing': instance.pricing,
  'operatingHours': instance.operatingHours,
  'isAvailable': instance.isAvailable,
  'slotBufferMins': instance.slotBufferMins,
  'averageRating': instance.averageRating,
  'totalReviews': instance.totalReviews,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

CreateTurfRequest _$CreateTurfRequestFromJson(
  Map<String, dynamic> json,
) => CreateTurfRequest(
  name: json['name'] as String,
  description: json['description'] as String,
  location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  amenities: (json['amenities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  dimensions: DimensionsModel.fromJson(
    json['dimensions'] as Map<String, dynamic>,
  ),
  sportType: (json['sportType'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  pricing: PricingModel.fromJson(json['pricing'] as Map<String, dynamic>),
  operatingHours: OperatingHoursModel.fromJson(
    json['operatingHours'] as Map<String, dynamic>,
  ),
  slotBufferMins: (json['slotBufferMins'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateTurfRequestToJson(CreateTurfRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'images': instance.images,
      'amenities': instance.amenities,
      'dimensions': instance.dimensions,
      'sportType': instance.sportType,
      'pricing': instance.pricing,
      'operatingHours': instance.operatingHours,
      'slotBufferMins': instance.slotBufferMins,
    };

UpdateTurfRequest _$UpdateTurfRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTurfRequest(
  name: json['name'] as String?,
  description: json['description'] as String?,
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  amenities: (json['amenities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  dimensions: json['dimensions'] == null
      ? null
      : DimensionsModel.fromJson(json['dimensions'] as Map<String, dynamic>),
  sportType: (json['sportType'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pricing: json['pricing'] == null
      ? null
      : PricingModel.fromJson(json['pricing'] as Map<String, dynamic>),
  operatingHours: json['operatingHours'] == null
      ? null
      : OperatingHoursModel.fromJson(
          json['operatingHours'] as Map<String, dynamic>,
        ),
  isAvailable: json['isAvailable'] as bool?,
  slotBufferMins: (json['slotBufferMins'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateTurfRequestToJson(UpdateTurfRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'images': instance.images,
      'amenities': instance.amenities,
      'dimensions': instance.dimensions,
      'sportType': instance.sportType,
      'pricing': instance.pricing,
      'operatingHours': instance.operatingHours,
      'isAvailable': instance.isAvailable,
      'slotBufferMins': instance.slotBufferMins,
    };
