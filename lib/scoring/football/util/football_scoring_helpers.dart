import 'package:flutter/material.dart';

import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../match_up/model/team_match_model.dart';
import '../model/football_match_event_model.dart';

List<AnnouncedPlayerModel> playingXiForTeam(
  TeamMatchModel match,
  String teamId,
) {
  if (teamId.isEmpty) return const [];
  return match.announcedPlayers
      .where((p) => p.teamIdHelper.getId() == teamId && !p.isSubstitute)
      .toList();
}

String eventKindLabel(FootballEventKind kind) {
  return switch (kind) {
    FootballEventKind.goal => 'Goal',
    FootballEventKind.ownGoal => 'Own goal',
    FootballEventKind.yellowCard => 'Yellow card',
    FootballEventKind.redCard => 'Red card',
    FootballEventKind.substitution => 'Substitution',
    FootballEventKind.penaltyScored => 'Penalty scored',
    FootballEventKind.penaltyMissed => 'Penalty missed',
  };
}

IconData eventKindIcon(FootballEventKind kind) {
  return switch (kind) {
    FootballEventKind.goal => Icons.sports_soccer,
    FootballEventKind.ownGoal => Icons.sports_soccer_outlined,
    FootballEventKind.yellowCard => Icons.square,
    FootballEventKind.redCard => Icons.square,
    FootballEventKind.substitution => Icons.swap_horiz,
    FootballEventKind.penaltyScored => Icons.flag,
    FootballEventKind.penaltyMissed => Icons.close,
  };
}
