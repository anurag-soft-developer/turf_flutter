import 'model/turf_model.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';

class TurfService {
  static final TurfService _instance = TurfService._internal();
  factory TurfService() => _instance;
  TurfService._internal();

  final ApiService _apiService = ApiService();

  Future<TurfModel?> createTurf(CreateTurfRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/turf',
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    final turf = TurfModel.fromJson(response);
    return turf;
  }

  Future<PaginatedResponse<TurfModel>?> searchTurfs({
    String? globalSearchText,
    List<String>? sportTypes,
    List<String>? amenities,
    LocationModel? location,
    /// Radius in km; omit to use [kDefaultNearbyRadiusKm].
    double? nearbyRadiusKm,
    double? minPrice,
    double? maxPrice,
    bool? includeWeekendSurge,
    bool? isAvailable,
    double? minRating,
    String? operatingTime,
    int page = 1,
    int limit = 10,
    String? sort,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (globalSearchText?.isNotEmpty == true) {
      queryParams['globalSearchText'] = globalSearchText;
    }
    if (sportTypes?.isNotEmpty == true) {
      queryParams['sportTypes'] = sportTypes!.join(',');
    }
    if (amenities?.isNotEmpty == true) {
      queryParams['amenities'] = amenities!.join(',');
    }
    if (location != null) {
      queryParams.addAll(
        nearbyLocationQueryParameters(
          nearbyLat: location.latitude,
          nearbyLng: location.longitude,
          nearbyRadiusKm: nearbyRadiusKm,
        ),
      );
    }
    if (minPrice != null) {
      queryParams['pricing[minPrice]'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['pricing[maxPrice]'] = maxPrice.toString();
    }
    if (includeWeekendSurge != null) {
      queryParams['pricing[includeWeekendSurge]'] = includeWeekendSurge
          .toString();
    }
    if (isAvailable != null) {
      queryParams['isAvailable'] = isAvailable.toString();
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating.toString();
    }
    if (operatingTime?.isNotEmpty == true) {
      queryParams['operatingTime'] = operatingTime;
    }
    if (sort?.isNotEmpty == true) {
      queryParams['sort'] = sort;
    }

    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final response = await _apiService.get<Map<String, dynamic>>(
      '/turf',
      queryParameters: queryParams,
    );

    if (response == null) {
      return EmptyPaginatedResponse<TurfModel>();
    }

    return PaginatedResponse.fromJson(
      response,
      (json) => TurfModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>?> getTurfStats() async {
    final response = await _apiService.get<Map<String, dynamic>>('/turf/stats');

    return response;
  }

  Future<TurfModel?> getTurfById(String turfId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/turf/$turfId',
    );

    if (response == null) {
      return null;
    }

    final turf = TurfModel.fromJson(response);
    return turf;
  }

  Future<TurfModel?> updateTurf(
    String turfId,
    UpdateTurfRequest request,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/turf/$turfId',
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    final updatedTurf = TurfModel.fromJson(response);
    return updatedTurf;
  }

  Future<bool> deleteTurf(String turfId) async {
    final response = await _apiService.delete('/turf/$turfId');
    return response != null;
  }

  /// Get featured/recommended turfs
  Future<List<TurfModel>?> getFeaturedTurfs({int limit = 5}) async {
    final result = await searchTurfs(
      sort: 'averageRating',
      limit: limit,
      minRating: 4.0,
    );
    return result?.data;
  }

  /// Get turfs owned by the current user
  Future<PaginatedResponse<TurfModel>?> getMyTurfs({
    int page = 1,
    int limit = 10,
    String? sort,
  }) async {
    final Map<String, dynamic> queryParams = {};

    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    if (sort?.isNotEmpty == true) {
      queryParams['sort'] = sort;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/turf/owner/my',
      queryParameters: queryParams,
    );

    if (response == null) {
      return EmptyPaginatedResponse<TurfModel>();
    }

    return PaginatedResponse.fromJson(
      response,
      (json) => TurfModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get turf statistics for the current user
  Future<Map<String, dynamic>?> getMyTurfStats() async {
    final response = await _apiService.get<Map<String, dynamic>>('/turf/stats');

    return response;
  }
}
