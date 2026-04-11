import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'members/team_member_service.dart';
import 'model/team_model.dart';

class TeamService {
  static final TeamService _instance = TeamService._internal();
  factory TeamService() => _instance;
  TeamService._internal();

  final ApiService _apiService = ApiService();

  /// Team roster / membership API (`/teams/:id/members`, `/team-members/me`).
  final TeamMemberService memberService = TeamMemberService();

  Future<TeamModel?> create(CreateTeamRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.team.base,
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamModel.fromJson(response);
  }

  /// Query params match backend `TeamFilterDto` (e.g. `lookingForMembers` / `teamOpenForMatch`
  /// as `'true'`/`'false'`, `limit` clamped to 50, nested `location[nearbyLat]` keys via [TeamFilterQuery]).
  Future<PaginatedResponse<TeamModel>?> findMany(TeamFilterQuery query) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.team.base,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<TeamModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TeamModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TeamModel?> findById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.team.byId(id),
    );
    if (response == null) return null;
    return TeamModel.fromJson(response);
  }

  Future<TeamModel?> update(String id, UpdateTeamRequest request) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.team.byId(id),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamModel.fromJson(response);
  }

  Future<bool> delete(String id) async {
    return _apiService.deleteResource(ApiConstants.team.byId(id));
  }

  Future<TeamModel?> promoteOwner(String teamId, PromoteOwnerRequest dto) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.team.promoteOwner(teamId),
      data: dto.toJson(),
    );
    if (response == null) return null;
    return TeamModel.fromJson(response);
  }

  Future<TeamModel?> demoteOwner(String teamId, String userId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.team.demoteOwner(teamId, userId),
    );
    if (response == null) return null;
    return TeamModel.fromJson(response);
  }
}
