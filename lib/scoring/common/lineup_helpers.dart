import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';

/// Live on-field announced players for [teamId] (empty stored ids → starting XI).
List<AnnouncedPlayerModel> activePlayersForTeam(
  TeamMatchModel match,
  String teamId,
) {
  if (teamId.isEmpty) return const [];

  final fromId = match.fromTeamHelper.getId() ?? '';
  final toId = match.toTeamHelper.getId() ?? '';

  List<String> stored = const [];
  var storedResolved = false;
  final cs = match.cricketState;
  if (cs != null) {
    if (teamId == fromId) {
      stored = cs.fromTeamActiveParticipantIds;
      storedResolved = true;
    } else if (teamId == toId) {
      stored = cs.toTeamActiveParticipantIds;
      storedResolved = true;
    }
  }
  if (!storedResolved) {
    final fs = match.footballState;
    if (fs != null) {
      if (teamId == fromId) {
        stored = fs.fromTeamActiveParticipantIds;
      } else if (teamId == toId) {
        stored = fs.toTeamActiveParticipantIds;
      }
    }
  }

  final Set<String> active;
  if (stored.isNotEmpty) {
    active = stored.toSet();
  } else {
    active = match.announcedPlayers
        .where(
          (p) =>
              (p.teamIdHelper.getId() ?? '') == teamId && !p.isSubstitute,
        )
        .map((p) => p.participantId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  if (active.isEmpty) return const [];
  return match.announcedPlayers
      .where((p) {
        final tid = p.teamIdHelper.getId() ?? '';
        final pid = p.participantId;
        return tid == teamId && pid != null && active.contains(pid);
      })
      .toList();
}
