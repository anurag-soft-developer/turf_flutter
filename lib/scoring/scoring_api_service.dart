import '../core/config/api_constants.dart';
import '../core/services/api_service.dart';
import '../match_up/model/team_match_model.dart';
import 'model/cricket_ball_event_model.dart';
import 'model/scoring_models.dart';

/// HTTP client for live scoring writes.
///
/// All scoring mutations (append ball / append event) are persisted by
/// turf-services over HTTP. Realtime broadcast is handled by turf-services
/// dispatching to realtime-turf-services and the socket pushing back the
/// resulting `scoring.update` to listeners.
class ScoringApiService {
  ScoringApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// `POST /scoring/cricket/matches/:teamMatchId/balls`
  ///
  /// Returns the updated [CricketOverEvent] containing this delivery.
  Future<CricketOverEvent?> appendCricketBall({
    required String teamMatchId,
    required AppendCricketBallRequest request,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.cricketSessionBalls(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return CricketOverEvent.fromJson(response);
  }

  /// `DELETE /scoring/cricket/matches/:teamMatchId/balls/last`
  Future<bool> undoLastCricketBall({required String teamMatchId}) async {
    return _apiService.deleteResource(
      ApiConstants.scoring.cricketUndoLastBall(teamMatchId),
    );
  }

  /// `POST /scoring/football/matches/:teamMatchId/events`
  ///
  /// Football models are not yet typed in Flutter, so this accepts the raw
  /// request body shape expected by `AppendFootballEventDto` in turf-services.
  // Future<Map<String, dynamic>?> appendFootballEvent({
  //   required String teamMatchId,
  //   required Map<String, dynamic> body,
  // }) async {
  //   return _apiService.post<Map<String, dynamic>>(
  //     ApiConstants.scoring.footballSessionEvents(teamMatchId),
  //     data: body,
  //   );
  // }

  /// `GET /scoring/cricket/matches/:teamMatchId`
  ///
  /// Returns the full [TeamMatchModel] (same shape as matchmaking `TeamMatch`).
  Future<TeamMatchModel?> getCricketSession(String teamMatchId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.scoring.cricketSession(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /scoring/cricket/matches/:teamMatchId/session`
  ///
  /// Initializes [TeamMatchModel.cricketState]; returns the updated match.
  Future<TeamMatchModel?> createCricketSession({
    required String teamMatchId,
    required CreateCricketSessionRequest request,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.cricketCreateSession(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `PATCH /scoring/cricket/matches/:teamMatchId/state`
  Future<TeamMatchModel?> updateCricketState({
    required String teamMatchId,
    required UpdateCricketStateRequest request,
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.scoring.cricketUpdateState(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /scoring/cricket/matches/:teamMatchId/inning/change`
  Future<TeamMatchModel?> changeCricketInning({
    required String teamMatchId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.cricketChangeInning(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `POST /scoring/cricket/matches/:teamMatchId/complete`
  Future<TeamMatchModel?> completeCricketMatch({
    required String teamMatchId,
    required CompleteCricketMatchRequest request,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.cricketCompleteMatch(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `GET /scoring/football/matches/:teamMatchId`
  Future<TeamMatchModel?> getFootballSession(String teamMatchId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.scoring.footballSession(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  /// `GET /scoring/cricket/matches/:teamMatchId/overs`
  ///
  /// All over documents for the match (`CricketOverEvent`, each with `ballEvents`).
  Future<List<CricketOverEvent>> listCricketOvers({
    required String teamMatchId,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.scoring.cricketSessionOvers(teamMatchId),
    );
    if (response == null) {
      return const [];
    }
    if (response is! List) {
      return const [];
    }
    return response
        .map(
          (e) => CricketOverEvent.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}
