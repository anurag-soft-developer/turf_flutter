import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import '../team/invites/team_invite_service.dart';
import '../tournament/tournament_service.dart';
import 'model/invitation_model.dart';

class InvitationService {
  static final InvitationService _instance = InvitationService._internal();
  factory InvitationService() => _instance;
  InvitationService._internal();

  final ApiService _api = ApiService();
  final TeamInviteService _teamInvites = TeamInviteService();
  final TournamentService _tournaments = TournamentService();

  Future<PaginatedResponse<InvitationModel>?> listMine({
    InvitationStatus? status,
    InvitationKind? kind,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status.name,
      if (kind != null) 'kind': kind.name,
    };
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.teamInvite.myInvites,
      queryParameters: params,
    );
    if (response == null) {
      return EmptyPaginatedResponse<InvitationModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => InvitationModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<bool> accept(InvitationModel invite) async {
    if (invite.isTournament) {
      final tournamentId = invite.tournamentId;
      if (tournamentId == null || tournamentId.isEmpty) return false;
      return _tournaments.acceptInvite(tournamentId, invite.id);
    }
    final updated = await _teamInvites.accept(invite.id);
    return updated != null;
  }

  Future<bool> decline(InvitationModel invite) async {
    if (invite.isTournament) {
      final tournamentId = invite.tournamentId;
      if (tournamentId == null || tournamentId.isEmpty) return false;
      return _tournaments.declineInvite(tournamentId, invite.id);
    }
    final updated = await _teamInvites.decline(invite.id);
    return updated != null;
  }
}
