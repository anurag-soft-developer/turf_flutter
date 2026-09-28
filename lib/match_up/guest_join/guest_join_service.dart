import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';

class GuestJoinStatus {
  const GuestJoinStatus({
    required this.fromTeamOpen,
    required this.toTeamOpen,
    required this.maxPerTeam,
    required this.openTeamIds,
    required this.joinedTeamId,
    required this.canSwitch,
    required this.counts,
  });

  final bool fromTeamOpen;
  final bool toTeamOpen;
  final int maxPerTeam;
  final List<String> openTeamIds;
  final String? joinedTeamId;
  final bool canSwitch;
  final Map<String, int> counts;

  factory GuestJoinStatus.fromJson(Map<String, dynamic> json) {
    final guestJoin = json['guestJoin'] as Map<String, dynamic>? ?? const {};
    final rawCounts = json['counts'] as Map<String, dynamic>? ?? const {};
    return GuestJoinStatus(
      fromTeamOpen: guestJoin['fromTeamOpen'] as bool? ?? false,
      toTeamOpen: guestJoin['toTeamOpen'] as bool? ?? false,
      maxPerTeam: (guestJoin['maxPerTeam'] as num?)?.toInt() ?? 0,
      openTeamIds: (json['openTeamIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      joinedTeamId: json['joinedTeamId'] as String?,
      canSwitch: json['canSwitch'] as bool? ?? false,
      counts: rawCounts.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}

class GuestJoinService {
  static final GuestJoinService _instance = GuestJoinService._internal();
  factory GuestJoinService() => _instance;
  GuestJoinService._internal();

  final ApiService _apiService = ApiService();

  Future<GuestJoinStatus?> updateSettings({
    required String matchId,
    required String actorTeamId,
    required bool open,
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.matchmaking.guestJoinSettings(matchId),
      data: <String, dynamic>{'actorTeamId': actorTeamId, 'open': open},
    );
    return response == null ? null : GuestJoinStatus.fromJson(response);
  }

  Future<GuestJoinStatus?> join({
    required String matchId,
    String? teamId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.matchmaking.guestJoin(matchId),
      data: <String, dynamic>{if (teamId != null) 'teamId': teamId},
    );
    return response == null ? null : GuestJoinStatus.fromJson(response);
  }

  Future<GuestJoinStatus?> leave(String matchId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.matchmaking.guestJoin(matchId),
    );
    return response == null ? null : GuestJoinStatus.fromJson(response);
  }
}
