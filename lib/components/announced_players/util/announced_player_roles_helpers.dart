import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../team/model/team_model.dart';

AnnouncedPlayerRole defaultAnnouncedRoleForSport(TeamSportType sport) {
  return switch (sport) {
    TeamSportType.cricket => AnnouncedPlayerRole.batsman,
    TeamSportType.football => AnnouncedPlayerRole.allrounder,
    _ => AnnouncedPlayerRole.allrounder,
  };
}

List<AnnouncedPlayerRole> announcedRolesForSport(TeamSportType sport) {
  return switch (sport) {
    TeamSportType.cricket || TeamSportType.football => AnnouncedPlayerRole.values,
    _ => [AnnouncedPlayerRole.allrounder],
  };
}

String announcedRoleLabelForSport(
  TeamSportType sport,
  AnnouncedPlayerRole role,
) {
  if (sport == TeamSportType.football) {
    return switch (role) {
      AnnouncedPlayerRole.batsman => 'Forward',
      AnnouncedPlayerRole.bowler => 'Defender',
      AnnouncedPlayerRole.allrounder => 'Midfielder',
      AnnouncedPlayerRole.wicketKeeper => 'Goalkeeper',
    };
  }
  return switch (role) {
    AnnouncedPlayerRole.batsman => 'Batsman',
    AnnouncedPlayerRole.bowler => 'Bowler',
    AnnouncedPlayerRole.allrounder => 'All-rounder',
    AnnouncedPlayerRole.wicketKeeper => 'Wicket-keeper',
  };
}
