import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';
import 'model/announced_player_model.dart';

/// Client for [AnnouncedPlayersController] (`/matchmaking/:matchId/announced-players`).
class AnnouncedPlayersService {
  static final AnnouncedPlayersService _instance =
      AnnouncedPlayersService._internal();
  factory AnnouncedPlayersService() => _instance;
  AnnouncedPlayersService._internal();

  final ApiService _apiService = ApiService();

  List<AnnouncedPlayerModel> _parsePlayerList(dynamic response) {
    if (response == null || response is! List) {
      return const [];
    }
    return response
        .map(
          (e) => AnnouncedPlayerModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  /// `GET /matchmaking/:matchId/announced-players?actorTeamId=`
  Future<List<AnnouncedPlayerModel>> listForTeam({
    required String teamMatchId,
    required String actorTeamId,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.matchmaking.announcedPlayers(teamMatchId),
      queryParameters: {'actorTeamId': actorTeamId},
    );
    return _parsePlayerList(response);
  }

  /// `POST /matchmaking/:matchId/announced-players`
  Future<List<AnnouncedPlayerModel>> addAnnouncedPlayers({
    required String teamMatchId,
    required String actorTeamId,
    required List<AnnouncedPlayerCreatePayload> players,
  }) async {
    final response = await _apiService.post<dynamic>(
      ApiConstants.matchmaking.announcedPlayers(teamMatchId),
      data: <String, dynamic>{
        'actorTeamId': actorTeamId,
        'players': players.map((p) => p.toJson()).toList(),
      },
    );
    return _parsePlayerList(response);
  }

  /// `DELETE /matchmaking/:matchId/announced-players`
  Future<List<AnnouncedPlayerModel>> removeAnnouncedPlayers({
    required String teamMatchId,
    required String actorTeamId,
    required List<String> userIds,
  }) async {
    final response = await _apiService.delete<dynamic>(
      ApiConstants.matchmaking.announcedPlayers(teamMatchId),
      data: <String, dynamic>{'actorTeamId': actorTeamId, 'userIds': userIds},
    );
    return _parsePlayerList(response);
  }

  /// `PATCH /matchmaking/:matchId/announced-players`
  Future<List<AnnouncedPlayerModel>> updateAnnouncedPlayers({
    required String teamMatchId,
    required String actorTeamId,
    required List<AnnouncedPlayerUpdatePayload> updates,
  }) async {
    final response = await _apiService.patch<dynamic>(
      ApiConstants.matchmaking.announcedPlayers(teamMatchId),
      data: <String, dynamic>{
        'actorTeamId': actorTeamId,
        'updates': updates.map((u) => u.toJson()).toList(),
      },
    );
    return _parsePlayerList(response);
  }
}
