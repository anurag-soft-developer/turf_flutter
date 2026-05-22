import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../match_up/model/team_match_model.dart';
import 'model/cricket_ball_event_model.dart';
import 'model/cricket_scoring_models.dart';

/// HTTP client for cricket live scoring.
class CricketScoringApiService {
  CricketScoringApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

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

  Future<bool> undoLastCricketBall({required String teamMatchId}) async {
    return _apiService.deleteResource(
      ApiConstants.scoring.cricketUndoLastBall(teamMatchId),
    );
  }

  Future<TeamMatchModel?> getCricketSession(String teamMatchId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.scoring.cricketSession(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

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

  Future<TeamMatchModel?> changeCricketInning({
    required String teamMatchId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.cricketChangeInning(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<TeamMatchModel?> completeCricketMatch({
    required String teamMatchId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.cricketCompleteMatch(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

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
          (e) => CricketOverEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
