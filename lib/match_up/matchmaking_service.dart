import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'model/team_match_model.dart';

/// Client for backend [MatchmakingController] / [MatchmakingService].
class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();

  final ApiService _apiService = ApiService();

  /// `POST /matchmaking/requests`
  Future<TeamMatchModel?> sendRequest(SendMatchRequest body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requests,
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `GET /matchmaking/requests`
  Future<PaginatedResponse<TeamMatchModel>?> listRequests(
    ListNegotiationsFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.matchmaking.requests,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<TeamMatchModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TeamMatchModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// `POST /matchmaking/requests/:id/respond`
  Future<TeamMatchModel?> respond(
    String matchId,
    RespondMatchRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestRespond(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /matchmaking/requests/:id/propose-schedule`
  Future<TeamMatchModel?> proposeSchedule(
    String matchId,
    ProposeScheduleRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestProposeSchedule(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /matchmaking/requests/:id/slots/decide`
  Future<TeamMatchModel?> decideSlotProposal(
    String matchId,
    DecideSlotProposalRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestSlotsDecide(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /matchmaking/requests/:id/turfs/decide`
  Future<TeamMatchModel?> decideTurfProposal(
    String matchId,
    DecideTurfProposalRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestTurfsDecide(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /matchmaking/requests/:id/finalize-schedule`
  Future<TeamMatchModel?> finalizeSchedule(
    String matchId,
    FinalizeScheduleRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestFinalizeSchedule(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /matchmaking/requests/:id/cancel`
  Future<TeamMatchModel?> cancel(
    String matchId,
    CancelNegotiationRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestCancel(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /matchmaking/requests/:id/match-result`
  Future<TeamMatchModel?> recordMatchResult(
    String matchId,
    RecordMatchResultRequest body,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestMatchResult(matchId),
      data: body.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }
}
