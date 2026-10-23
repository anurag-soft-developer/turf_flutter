import 'package:dio/dio.dart';

import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'model/tournament_models.dart';

class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  final ApiService _api = ApiService();

  Future<TournamentModel?> create({
    required String name,
    required String format,
    int? maxTeams,
    int? maxOvers,
    List<String>? coverImages,
    String? venueName,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? ballType,
    String? pitchType,
    String? matchType,
    int? durationMinutes,
    String sportType = 'cricket',
  }) async {
    final covers = coverImages?.where((url) => url.trim().isNotEmpty).toList();
    final location = venueName?.trim();
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.base,
      data: {
        'name': name,
        'format': format,
        if (maxTeams != null) 'maxTeams': maxTeams,
        if (maxOvers != null) 'maxOvers': maxOvers,
        'sportType': sportType,
        if (covers != null && covers.isNotEmpty) 'coverImages': covers,
        if (location != null && location.isNotEmpty) 'venueName': location,
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (ballType != null && ballType.isNotEmpty) 'ballType': ballType,
        if (pitchType != null && pitchType.isNotEmpty) 'pitchType': pitchType,
        if (matchType != null && matchType.isNotEmpty) 'matchType': matchType,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      },
    );
    if (response == null) return null;
    return TournamentModel.fromJson(response);
  }

  Future<TournamentModel?> updateDraft(
    String id, {
    String? name,
    String? format,
    int? maxTeams,
    int? maxOvers,
    List<String>? coverImages,
    String? sportType,
    String? description,
    String? venueName,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    bool? isPublic,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (format != null) 'format': format,
      if (maxTeams != null) 'maxTeams': maxTeams,
      if (maxOvers != null) 'maxOvers': maxOvers,
      if (coverImages != null) 'coverImages': coverImages,
      if (sportType != null) 'sportType': sportType,
      if (description != null) 'description': description,
      if (venueName != null) 'venueName': venueName,
      if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      if (registrationDeadline != null)
        'registrationDeadline': registrationDeadline.toUtc().toIso8601String(),
      if (isPublic != null) 'isPublic': isPublic,
    };
    if (data.isEmpty) return null;
    final response = await _api.patch<Map<String, dynamic>>(
      ApiConstants.tournaments.byId(id),
      data: data,
    );
    if (response == null) return null;
    return TournamentModel.fromJson(response);
  }

  Future<TournamentPage?> listOpen({int page = 1}) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.tournaments.open,
      queryParameters: {'page': page, 'limit': 20},
    );
    if (response == null) return null;
    return TournamentPage.fromJson(response);
  }

  Future<TournamentPage?> listMine({
    int page = 1,
    String? sportType,
    List<String>? status,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.tournaments.mine,
      queryParameters: {
        'page': page,
        'limit': 20,
        if (sportType != null && sportType.isNotEmpty) 'sportType': sportType,
        if (status != null && status.isNotEmpty) 'status': status.join(','),
      },
    );
    if (response == null) return null;
    return TournamentPage.fromJson(response);
  }

  Future<List<TournamentTeamRef>> actingTeams() async {
    final response = await _api.get<dynamic>(
      ApiConstants.tournaments.actingTeams,
    );
    return _asMaps(response)
        .map(TournamentTeamRef.fromJson)
        .where((team) => team.id.isNotEmpty)
        .toList();
  }

  Future<TournamentModel?> getOne(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.tournaments.byId(id),
    );
    if (response == null) return null;
    return TournamentModel.fromJson(response);
  }

  Future<PaginatedResponse<TournamentEntryModel>> entries(
    String id, {
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.tournaments.entries(id),
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      },
    );
    if (response == null) {
      return EmptyPaginatedResponse<TournamentEntryModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => TournamentEntryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<TournamentFixtureModel>> fixtures(String id) async {
    final response = await _api.get<dynamic>(
      ApiConstants.tournaments.fixtures(id),
    );
    return _asMaps(response).map(TournamentFixtureModel.fromJson).toList();
  }

  Future<TournamentTableModel?> table(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.tournaments.table(id),
    );
    if (response == null) return null;
    return TournamentTableModel.fromJson(response);
  }

  Future<bool> invite(String id, String teamId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitations(id),
      data: {'teamId': teamId, 'direction': 'invite'},
    );
    return response != null;
  }

  Future<bool> requestToJoin(String id, String teamId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitations(id),
      data: {'teamId': teamId, 'direction': 'request'},
    );
    return response != null;
  }

  Future<bool> acceptInvite(String id, String invitationId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitationAction(id, invitationId, 'accept'),
    );
    return response != null;
  }

  Future<bool> declineInvite(String id, String invitationId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitationAction(id, invitationId, 'decline'),
    );
    return response != null;
  }

  Future<bool> revokeInvite(String id, String invitationId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitationAction(id, invitationId, 'revoke'),
    );
    return response != null;
  }

  Future<bool> acceptRequest(String id, String invitationId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitationAction(id, invitationId, 'accept'),
    );
    return response != null;
  }

  Future<bool> declineRequest(String id, String invitationId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitationAction(id, invitationId, 'decline'),
    );
    return response != null;
  }

  Future<bool> withdrawRequest(String id, String invitationId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.invitationAction(id, invitationId, 'withdraw'),
    );
    return response != null;
  }

  Future<bool> addOrganizer(String id, String userId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.organizers(id),
      data: {'userId': userId},
    );
    return response != null;
  }

  Future<bool> removeOrganizer(String id, String userId) async {
    final response = await _api.delete<Map<String, dynamic>>(
      ApiConstants.tournaments.organizer(id, userId),
    );
    return response != null;
  }

  Future<bool> lockRoster(String id) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.lockRoster(id),
    );
    return response != null;
  }

  Future<bool> removeAcceptedTeam(String id, String entryId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.removeEntry(id, entryId),
    );
    return response != null;
  }

  Future<bool> generateDraw(String id) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.draw(id),
    );
    return response != null;
  }

  Future<bool> cancel(String id) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.cancel(id),
    );
    return response != null;
  }

  Future<bool> deleteTournament(String id) async {
    return _api.deleteResource(ApiConstants.tournaments.byId(id));
  }

  Future<bool> pickBracketWinner(
    String id,
    String matchId,
    String teamId,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.bracketWinner(id, matchId),
      data: {'teamId': teamId},
    );
    return response != null;
  }

  Future<bool> pickQualifiers(
    String id,
    String groupLabel,
    List<String> teamIds,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.tournaments.qualifiers(id),
      data: {'groupLabel': groupLabel, 'teamIds': teamIds},
    );
    return response != null;
  }

  Future<bool> updateFixtureTeams(
    String id,
    String matchId, {
    String? fromTeamId,
    String? toTeamId,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      ApiConstants.tournaments.fixtureTeams(id, matchId),
      data: {'fromTeamId': fromTeamId, 'toTeamId': toTeamId},
      options: Options(extra: const {'preserveNulls': true}),
    );
    return response != null;
  }
}

List<Map<String, dynamic>> _asMaps(dynamic response) {
  final raw = response is Map && response['items'] is List
      ? response['items']
      : response;
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}
