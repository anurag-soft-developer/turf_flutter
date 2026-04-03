import 'package:json_annotation/json_annotation.dart';

part 'location_model.g.dart';

List<double> _geoJsonCoordinatesFromJson(dynamic json) {
  final list = json as List<dynamic>;
  if (list.length != 2) {
    throw const FormatException(
      'GeoJSON Point coordinates must be [longitude, latitude]',
    );
  }
  return [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
}

List<dynamic> _geoJsonCoordinatesToJson(List<double> coordinates) =>
    coordinates;

/// GeoJSON `Point` as stored by MongoDB: `coordinates` are `[longitude, latitude]`.
@JsonSerializable(explicitToJson: true)
class GeoPointModel {
  static const String geoJsonTypePoint = 'Point';

  @JsonKey(defaultValue: geoJsonTypePoint)
  final String type;

  /// MongoDB / GeoJSON order: `[longitude, latitude]`.
  @JsonKey(
    fromJson: _geoJsonCoordinatesFromJson,
    toJson: _geoJsonCoordinatesToJson,
  )
  final List<double> coordinates;

  GeoPointModel({
    this.type = geoJsonTypePoint,
    required this.coordinates,
  }) : assert(
          coordinates.length == 2,
          'coordinates must be [longitude, latitude]',
        );

  factory GeoPointModel.fromLngLat({
    required double longitude,
    required double latitude,
  }) =>
      GeoPointModel(coordinates: [longitude, latitude]);

  /// Longitude (index 0).
  double get longitude => coordinates[0];

  /// Latitude (index 1).
  double get latitude => coordinates[1];

  double get lng => longitude;

  double get lat => latitude;

  factory GeoPointModel.fromJson(Map<String, dynamic> json) =>
      _$GeoPointModelFromJson(json);

  Map<String, dynamic> toJson() => _$GeoPointModelToJson(this);

  GeoPointModel copyWith({String? type, List<double>? coordinates}) {
    return GeoPointModel(
      type: type ?? this.type,
      coordinates: coordinates ?? List<double>.from(this.coordinates),
    );
  }

  @override
  String toString() =>
      'GeoPointModel(type: $type, lng: $longitude, lat: $latitude)';
}

@JsonSerializable(explicitToJson: true)
class LocationModel {
  final String address;
  final GeoPointModel coordinates;

  LocationModel({required this.address, required this.coordinates});

  double get longitude => coordinates.longitude;

  double get latitude => coordinates.latitude;

  double get lng => coordinates.lng;

  double get lat => coordinates.lat;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);

  LocationModel copyWith({String? address, GeoPointModel? coordinates}) {
    return LocationModel(
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  @override
  String toString() => 'LocationModel(address: $address, coordinates: $coordinates)';
}

/// Server defaults/range for `nearbyLocationQuerySchema.nearbyRadiusKm`.
const double kDefaultNearbyRadiusKm = 10;
const double kMinNearbyRadiusKm = 0.1;
const double kMaxNearbyRadiusKm = 500;

/// Flat query entries for `location: nearbyLocationQuerySchema` (e.g. `location[nearbyLat]`).
Map<String, String> nearbyLocationQueryParameters({
  required double nearbyLat,
  required double nearbyLng,
  double? nearbyRadiusKm,
}) {
  final km = (nearbyRadiusKm ?? kDefaultNearbyRadiusKm)
      .clamp(kMinNearbyRadiusKm, kMaxNearbyRadiusKm)
      .toDouble();
  return {
    'location[nearbyLat]': nearbyLat.toString(),
    'location[nearbyLng]': nearbyLng.toString(),
    'location[nearbyRadiusKm]': km.toString(),
  };
}
