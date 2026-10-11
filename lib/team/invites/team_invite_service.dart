import '../../core/config/api_constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/services/api_service.dart';
import '../../invitations/model/invitation_model.dart';

class TeamInviteService {
  static final TeamInviteService _instance = TeamInviteService._internal();
  factory TeamInviteService() => _instance;
  TeamInviteService._internal();

  final ApiService _apiService = ApiService();

  Future<InvitationModel?> create(
    String teamId,
    CreateTeamInviteRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.create(teamId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }

  Future<PaginatedResponse<InvitationModel>?> listForTeam(
    String teamId,
    TeamInviteFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.teamInvite.listForTeam(teamId),
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<InvitationModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => InvitationModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<bool> revoke(String teamId, String inviteId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.revoke(teamId, inviteId),
    );
    return response != null && response['success'] == true;
  }

  Future<InvitationModel?> accept(String inviteId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.accept(inviteId),
    );
    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }

  Future<InvitationModel?> decline(String inviteId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.teamInvite.decline(inviteId),
    );
    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }
}

/// Query for the team owner's invitation list.
class TeamInviteFilterQuery {
  final InvitationStatus? status;
  final int page;
  final int limit;

  const TeamInviteFilterQuery({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status!.name;
    return params;
  }
}

class CreateTeamInviteRequest {
  final String? email;
  final String? phone;
  final String? inviteeUserId;

  CreateTeamInviteRequest({
    this.email,
    this.phone,
    this.inviteeUserId,
  }) : assert(
          (email != null ? 1 : 0) +
                  (phone != null ? 1 : 0) +
                  (inviteeUserId != null ? 1 : 0) ==
              1,
          'Provide exactly one of email, phone, or inviteeUserId',
        );

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (inviteeUserId != null) 'inviteeUserId': inviteeUserId,
      };
}
