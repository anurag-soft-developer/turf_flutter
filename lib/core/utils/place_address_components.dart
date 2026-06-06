import 'package:dio/dio.dart';
import 'package:google_places_flutter/model/place_details.dart';

import '../config/env_config.dart';
import '../models/location_model.dart';

String? _componentLongName(List<AddressComponents>? components, String type) {
  if (components == null) return null;
  for (final component in components) {
    if (component.types?.contains(type) ?? false) {
      final name = component.longName?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
  }
  return null;
}

ParsedAddressComponents parseGoogleAddressComponents(
  List<AddressComponents>? components,
) {
  if (components == null || components.isEmpty) {
    return const ParsedAddressComponents();
  }

  final city =
      _componentLongName(components, 'locality') ??
      _componentLongName(components, 'postal_town') ??
      _componentLongName(components, 'administrative_area_level_2');

  return ParsedAddressComponents(
    city: city,
    state: _componentLongName(components, 'administrative_area_level_1'),
    zip: _componentLongName(components, 'postal_code'),
    country: _componentLongName(components, 'country'),
  );
}

class ParsedAddressComponents {
  final String? city;
  final String? state;
  final String? zip;
  final String? country;

  const ParsedAddressComponents({
    this.city,
    this.state,
    this.zip,
    this.country,
  });
}

Future<ParsedAddressComponents> fetchAddressComponentsForPlaceId(
  String placeId,
) async {
  final apiKey = EnvConfig.googlePlacesApiKey.trim();
  if (apiKey.isEmpty || placeId.trim().isEmpty) {
    return const ParsedAddressComponents();
  }

  try {
    final dio = Dio();
    final response = await dio.get<Map<String, dynamic>>(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: {
        'placeid': placeId,
        'fields': 'address_components',
        'key': apiKey,
      },
    );

    final details = PlaceDetails.fromJson(response.data ?? {});
    return parseGoogleAddressComponents(
      details.result?.addressComponents,
    );
  } catch (_) {
    return const ParsedAddressComponents();
  }
}

SelectedLocation selectedLocationFromPrediction({
  required String address,
  required double latitude,
  required double longitude,
  ParsedAddressComponents components = const ParsedAddressComponents(),
}) {
  return SelectedLocation(
    address: address,
    latitude: latitude,
    longitude: longitude,
    city: components.city,
    state: components.state,
    zip: components.zip,
    country: components.country,
  );
}
