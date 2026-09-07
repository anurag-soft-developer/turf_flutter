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

  /// `GET /matchmaking/requests/:id`
  Future<TeamMatchModel?> getTeamMatchById(String matchId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.matchmaking.requestById(matchId),
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

  /// `GET /matchmaking/inbox?type=incoming|outgoing`
  Future<PaginatedResponse<TeamMatchModel>?> listInbox(
    ListPreMatchInboxFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.matchmaking.inbox,
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

  /// `GET /matchmaking/active-opponent-ids`
  Future<ActiveOpponentIds> listActiveOpponentIds() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.matchmaking.activeOpponentIds,
    );
    return parseActiveOpponentIds(response);
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

  /// `PATCH /matchmaking/requests/:id`
  Future<TeamMatchModel?> updateRequest(
    String matchId,
    UpdateTeamMatchRequest body,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.matchmaking.updateById(matchId),
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

class ActiveOpponentIds {
  const ActiveOpponentIds({
    this.sentByTeamId = const {},
    this.receivedByTeamId = const {},
  });

  final Map<String, Set<String>> sentByTeamId;
  final Map<String, Set<String>> receivedByTeamId;
}

Map<String, Set<String>> _parseOpponentIdMap(dynamic raw) {
  if (raw is! Map) return {};
  final out = <String, Set<String>>{};
  for (final entry in raw.entries) {
    final teamId = entry.key.toString();
    final ids = entry.value;
    if (teamId.isEmpty || ids is! List) continue;
    out[teamId] = ids
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }
  return out;
}

ActiveOpponentIds parseActiveOpponentIds(Map<String, dynamic>? json) {
  return ActiveOpponentIds(
    sentByTeamId: _parseOpponentIdMap(json?['sentByTeamId']),
    receivedByTeamId: _parseOpponentIdMap(json?['receivedByTeamId']),
  );
}
