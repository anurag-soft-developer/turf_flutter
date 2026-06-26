import '../model/team_match_model.dart';

/// Whether the current user is on the incoming ([toTeam]) side of the challenge.
///
/// Aligns with [MatchChallengesScreen] list logic: [toTeam] received the request.
bool resolveIsIncoming(TeamMatchModel match, Set<String> myTeamIds) {
  final toId = match.toTeamHelper.getId();
  final fromId = match.fromTeamHelper.getId();
  final onTo = toId != null && myTeamIds.contains(toId);
  final onFrom = fromId != null && myTeamIds.contains(fromId);
  if (onTo && !onFrom) return true;
  if (onFrom && !onTo) return false;
  if (onTo) return true;
  return false;
}
