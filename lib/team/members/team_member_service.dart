import '../../core/config/api_constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/services/api_service.dart';
import 'model/team_member_model.dart';

class TeamMemberService {
  static final TeamMemberService _instance = TeamMemberService._internal();
  factory TeamMemberService() => _instance;
  TeamMemberService._internal();

  final ApiService _apiService = ApiService();

  Future<TeamMemberModel?> join(String teamId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamMember.join(teamId),
    );
    if (response == null) return null;
    return TeamMemberModel.fromJson(response);
  }

  Future<PaginatedResponse<TeamMemberModel>?> listForTeam(
    String teamId,
    TeamMemberRosterFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.teamMember.membersBase(teamId),
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<TeamMemberModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TeamMemberModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TeamMemberModel?> updateMember(
    String teamId,
    String membershipId,
    UpdateTeamMemberRequest request,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.teamMember.member(teamId, membershipId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMemberModel.fromJson(response);
  }

  /// Owner-only. [request] without [SuspendTeamMemberRequest.suspendedUntil] suspends indefinitely.
  Future<TeamMemberModel?> suspendMember(
    String teamId,
    String membershipId, {
    SuspendTeamMemberRequest request = const SuspendTeamMemberRequest(),
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamMember.suspend(teamId, membershipId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMemberModel.fromJson(response);
  }

  /// Owner-only. Restores a suspended member to [TeamMemberStatus.active].
  Future<TeamMemberModel?> unsuspendMember(
    String teamId,
    String membershipId,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamMember.unsuspend(teamId, membershipId),
    );
    if (response == null) return null;
    return TeamMemberModel.fromJson(response);
  }

  Future<TeamMemberModel?> acceptRequest(
    String teamId,
    String membershipId,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamMember.accept(teamId, membershipId),
    );
    if (response == null) return null;
    return TeamMemberModel.fromJson(response);
  }

  Future<TeamMemberModel?> rejectRequest(
    String teamId,
    String membershipId,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamMember.reject(teamId, membershipId),
    );
    if (response == null) return null;
    return TeamMemberModel.fromJson(response);
  }

  Future<LeaveTeamResponse?> leave(String teamId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamMember.leave(teamId),
    );
    if (response == null) return null;
    return LeaveTeamResponse.fromJson(response);
  }

  Future<bool> removeMember(String teamId, String targetUserId) async {
    return _apiService.deleteResource(
      ApiConstants.teamMember.removeUser(teamId, targetUserId),
    );
  }

  Future<PaginatedResponse<TeamMemberModel>?> myMemberships(
    MyTeamMembershipsFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.teamMembershipSelf.myMemberships,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<TeamMemberModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TeamMemberModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
