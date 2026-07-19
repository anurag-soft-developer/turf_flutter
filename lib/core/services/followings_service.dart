import '../config/api_constants.dart';
import '../models/following/following_model.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class FollowingsService {
  static final FollowingsService _instance = FollowingsService._internal();
  factory FollowingsService() => _instance;
  FollowingsService._internal();

  final ApiService _apiService = ApiService();

  /// Creates an accepted follow edge (`POST /followings/request`).
  Future<FollowingModel?> follow(String recipientId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.followings.request,
      data: {'recipientId': recipientId, 'recipientType': 'User'},
    );
    if (response == null) return null;
    return FollowingModel.fromJson(response);
  }

  /// Removes a follow edge by id (`DELETE /followings/:id`).
  Future<bool> unfollow(String followingId) {
    return _apiService.deleteResource(
      ApiConstants.followings.byId(followingId),
    );
  }

  /// The logged-in user's outgoing edge towards [recipientId], or null when
  /// not following (used for follow-button state and unfollow id).
  Future<FollowingModel?> getOutgoingEdge(String recipientId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.followings.base,
      queryParameters: {
        'direction': 'outgoing',
        'recipientType': 'User',
        'recipientId': recipientId,
        'page': 1,
        'limit': 1,
      },
    );
    if (response == null) return null;
    final result = PaginatedResponse.fromJson(
      response,
      (json) => FollowingModel.fromJson(json as Map<String, dynamic>),
    );
    return result.data.isNotEmpty ? result.data.first : null;
  }

  Future<PaginatedResponse<FollowingModel>?> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) {
    return _getEdgeList(
      ApiConstants.followings.userFollowers(userId),
      page: page,
      limit: limit,
    );
  }

  Future<PaginatedResponse<FollowingModel>?> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) {
    return _getEdgeList(
      ApiConstants.followings.userFollowing(userId),
      page: page,
      limit: limit,
    );
  }

  Future<PaginatedResponse<FollowingModel>?> _getEdgeList(
    String endpoint, {
    required int page,
    required int limit,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'page': page, 'limit': limit},
    );
    if (response == null) {
      return EmptyPaginatedResponse<FollowingModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => FollowingModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
