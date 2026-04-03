// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoPointModel _$GeoPointModelFromJson(Map<String, dynamic> json) =>
    GeoPointModel(
      type: json['type'] as String? ?? 'Point',
      coordinates: _geoJsonCoordinatesFromJson(json['coordinates']),
    );

Map<String, dynamic> _$GeoPointModelToJson(GeoPointModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': _geoJsonCoordinatesToJson(instance.coordinates),
    };

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      address: json['address'] as String,
      coordinates: GeoPointModel.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'coordinates': instance.coordinates.toJson(),
    };
