import '../../core/config/api_constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/services/api_service.dart';
import 'model/team_invite_model.dart';

class TeamInviteService {
  static final TeamInviteService _instance = TeamInviteService._internal();
  factory TeamInviteService() => _instance;
  TeamInviteService._internal();

  final ApiService _apiService = ApiService();

  Future<TeamInviteModel?> create(
    String teamId,
    CreateTeamInviteRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.create(teamId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamInviteModel.fromJson(response);
  }

  Future<PaginatedResponse<TeamInviteModel>?> listForTeam(
    String teamId,
    TeamInviteFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.teamInvite.listForTeam(teamId),
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<TeamInviteModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TeamInviteModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<bool> revoke(String teamId, String inviteId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.revoke(teamId, inviteId),
    );
    return response != null && response['success'] == true;
  }

  Future<PaginatedResponse<TeamInviteModel>?> listMine(
    TeamInviteFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.teamInvite.myInvites,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<TeamInviteModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TeamInviteModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TeamInviteModel?> accept(String inviteId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.accept(inviteId),
    );
    if (response == null) return null;
    return TeamInviteModel.fromJson(response);
  }

  Future<TeamInviteModel?> reject(String inviteId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.reject(inviteId),
    );
    if (response == null) return null;
    return TeamInviteModel.fromJson(response);
  }
}
