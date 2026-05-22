import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../match_up/model/team_match_model.dart';
import 'model/football_match_event_model.dart';
import 'model/football_scoring_models.dart';

/// HTTP client for football live scoring.
class FootballScoringApiService {
  FootballScoringApiService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<TeamMatchModel?> getFootballSession(String teamMatchId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.scoring.footballSession(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<TeamMatchModel?> createFootballSession({
    required String teamMatchId,
    required CreateFootballSessionRequest request,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.footballCreateSession(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<FootballMatchEvent?> appendFootballEvent({
    required String teamMatchId,
    required AppendFootballEventRequest request,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.footballSessionEvents(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return FootballMatchEvent.fromJson(response);
  }

  Future<List<FootballMatchEvent>> listFootballEvents({
    required String teamMatchId,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.scoring.footballSessionEvents(teamMatchId),
    );
    if (response == null) return const [];
    if (response is! List) return const [];
    return response
        .map(
          (e) =>
              FootballMatchEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<bool> undoLastFootballEvent({required String teamMatchId}) async {
    return _apiService.deleteResource(
      ApiConstants.scoring.footballUndoLastEvent(teamMatchId),
    );
  }

  Future<TeamMatchModel?> changeFootballInning({
    required String teamMatchId,
    ChangeFootballInningRequest request = const ChangeFootballInningRequest(),
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.footballChangeInning(teamMatchId),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<TeamMatchModel?> pauseFootballTimer({
    required String teamMatchId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.footballPauseTimer(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<TeamMatchModel?> resumeFootballTimer({
    required String teamMatchId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.footballResumeTimer(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<TeamMatchModel?> completeFootballMatch({
    required String teamMatchId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.scoring.footballCompleteMatch(teamMatchId),
    );
    if (response == null) return null;
    return TeamMatchModel.fromJson(response);
  }

  Future<Map<String, dynamic>?> getFootballPoints({
    required String teamMatchId,
  }) async {
    return _apiService.get<Map<String, dynamic>>(
      ApiConstants.scoring.footballSessionPoints(teamMatchId),
    );
  }
}
