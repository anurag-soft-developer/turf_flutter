import '../config/api_constants.dart';
import '../models/location_model.dart';
import 'api_service.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['placeId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      mainText: json['mainText']?.toString() ?? '',
      secondaryText: json['secondaryText']?.toString() ?? '',
    );
  }
}

class PlacesService {
  PlacesService._();

  static final PlacesService instance = PlacesService._();
  final ApiService _api = ApiService();

  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    required String country,
    bool citiesOnly = false,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.places.autocomplete,
      queryParameters: {
        'input': input,
        'country': country,
        'citiesOnly': citiesOnly,
      },
    );
    final suggestions = response?['suggestions'];
    if (suggestions is! List) return const [];
    return suggestions
        .whereType<Map>()
        .map(
          (item) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.placeId.isNotEmpty && item.description.isNotEmpty)
        .toList();
  }

  Future<SelectedLocation?> details(PlaceSuggestion suggestion) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.places.details,
      queryParameters: {'placeId': suggestion.placeId},
    );
    if (response == null) return null;
    final latitude = (response['latitude'] as num?)?.toDouble();
    final longitude = (response['longitude'] as num?)?.toDouble();
    final address = response['address']?.toString() ?? '';
    if (latitude == null || longitude == null || address.isEmpty) return null;

    return SelectedLocation(
      address: address,
      latitude: latitude,
      longitude: longitude,
      city: _optionalString(response['city']),
      state: _optionalString(response['state']),
      zip: _optionalString(response['zip']),
      country: _optionalString(response['country']),
    );
  }
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
