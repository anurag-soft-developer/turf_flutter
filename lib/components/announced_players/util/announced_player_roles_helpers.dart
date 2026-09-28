import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../team/model/team_model.dart';

AnnouncedPlayerRole defaultAnnouncedRoleForSport(TeamSportType sport) {
  return switch (sport) {
    TeamSportType.cricket => AnnouncedPlayerRole.batsman,
    TeamSportType.football => AnnouncedPlayerRole.midfielder,
    _ => AnnouncedPlayerRole.allrounder,
  };
}

List<AnnouncedPlayerRole> announcedRolesForSport(TeamSportType sport) {
  return switch (sport) {
    TeamSportType.cricket => [
        AnnouncedPlayerRole.batsman,
        AnnouncedPlayerRole.bowler,
        AnnouncedPlayerRole.allrounder,
        AnnouncedPlayerRole.wicketKeeper,
      ],
    TeamSportType.football => [
        AnnouncedPlayerRole.forward,
        AnnouncedPlayerRole.defender,
        AnnouncedPlayerRole.midfielder,
        AnnouncedPlayerRole.goalkeeper,
      ],
    _ => [AnnouncedPlayerRole.allrounder],
  };
}

String announcedRoleLabelForSport(
  TeamSportType sport,
  AnnouncedPlayerRole role,
) {
  if (sport == TeamSportType.football) {
    return switch (role) {
      AnnouncedPlayerRole.forward => 'Forward',
      AnnouncedPlayerRole.defender => 'Defender',
      AnnouncedPlayerRole.midfielder => 'Midfielder',
      AnnouncedPlayerRole.goalkeeper => 'Goalkeeper',
      AnnouncedPlayerRole.batsman => 'Batsman',
      AnnouncedPlayerRole.bowler => 'Bowler',
      AnnouncedPlayerRole.allrounder => 'All-rounder',
      AnnouncedPlayerRole.wicketKeeper => 'Wicket-keeper',
    };
  }
  return switch (role) {
    AnnouncedPlayerRole.batsman => 'Batsman',
    AnnouncedPlayerRole.bowler => 'Bowler',
    AnnouncedPlayerRole.allrounder => 'All-rounder',
    AnnouncedPlayerRole.wicketKeeper => 'Wicket-keeper',
    AnnouncedPlayerRole.forward => 'Forward',
    AnnouncedPlayerRole.defender => 'Defender',
    AnnouncedPlayerRole.midfielder => 'Midfielder',
    AnnouncedPlayerRole.goalkeeper => 'Goalkeeper',
  };
}
