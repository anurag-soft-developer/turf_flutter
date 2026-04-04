import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'model/local_match_model.dart';

class LocalMatchService {
  static final LocalMatchService _instance = LocalMatchService._internal();
  factory LocalMatchService() => _instance;
  LocalMatchService._internal();

  final ApiService _apiService = ApiService();

  static const String _basePath = '/local-matches';

  Future<LocalMatchModel?> create(CreateLocalMatchRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      _basePath,
      data: request.toJson(),
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<PaginatedResponse<LocalMatchModel>?> findMany({
    LocalMatchVisibility? visibility,
    LocalMatchStatus? status,
    List<String>? sportTypes,
    int page = 1,
    int limit = 10,
    double? nearbyLat,
    double? nearbyLng,
    double? nearbyRadiusKm,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (visibility != null) {
      queryParams['visibility'] = visibility.name;
    }
    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (sportTypes?.isNotEmpty == true) {
      queryParams['sportTypes'] = sportTypes!.join(',');
    }
    if (nearbyLat != null && nearbyLng != null) {
      queryParams.addAll(
        nearbyLocationQueryParameters(
          nearbyLat: nearbyLat,
          nearbyLng: nearbyLng,
          nearbyRadiusKm: nearbyRadiusKm,
        ),
      );
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: queryParams,
    );

    if (response == null) {
      return EmptyPaginatedResponse<LocalMatchModel>();
    }

    return PaginatedResponse.fromJson(
      response,
      (json) => LocalMatchModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<LocalMatchModel?> findById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '$_basePath/$id',
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<LocalMatchModel?> update(
    String id,
    UpdateLocalMatchRequest request,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '$_basePath/$id',
      data: request.toJson(),
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<bool> delete(String id) async {
    return _apiService.deleteResource('$_basePath/$id');
  }

  Future<LocalMatchModel?> join(String id) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '$_basePath/$id/join',
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<LocalMatchModel?> acceptJoinRequest(
    String matchId,
    String requestId,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '$_basePath/$matchId/join-requests/$requestId/accept',
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<LocalMatchModel?> rejectJoinRequest(
    String matchId,
    String requestId,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '$_basePath/$matchId/join-requests/$requestId/reject',
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<LocalMatchModel?> promoteHost(
    String matchId,
    PromoteHostRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '$_basePath/$matchId/hosts',
      data: body.toJson(),
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<LocalMatchModel?> demoteHost(
    String matchId,
    String targetUserId,
  ) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '$_basePath/$matchId/hosts/$targetUserId',
    );
    if (response == null) {
      return null;
    }
    return LocalMatchModel.fromJson(response);
  }

  Future<bool> leave(String matchId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '$_basePath/$matchId/leave',
    );
    if (response == null) {
      return false;
    }
    return response['success'] == true;
  }
}
