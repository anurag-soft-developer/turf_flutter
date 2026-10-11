import '../core/models/team/team_ref_field_instance.dart';
import 'model/tournament_models.dart';

class TournamentPodiumTeam {
  const TournamentPodiumTeam({
    required this.id,
    required this.name,
    this.logo = '',
  });

  final String id;
  final String name;
  final String logo;
}

class TournamentPodium {
  const TournamentPodium({this.first, this.second, this.third});

  final TournamentPodiumTeam? first;
  final TournamentPodiumTeam? second;
  final TournamentPodiumTeam? third;

  bool get isEmpty => first == null && second == null && third == null;
}

/// 1st, 2nd, and 3rd once the tournament is completed.
/// League uses the table. Knockout and hybrid use the final, with 3rd as the
/// semi-finalist who lost to the champion.
TournamentPodium? tournamentPodium({
  required TournamentModel tournament,
  required List<TournamentFixtureModel> fixtures,
  required TournamentTableModel? table,
  required List<TournamentEntryModel> entries,
}) {
  if (tournament.status != 'completed') return null;
  final faces = _teamFaces(fixtures, entries, table);
  final places = tournament.format == 'league'
      ? _leaguePlaces(table)
      : _knockoutPlaces(fixtures);
  if (places == null) return null;
  final podium = TournamentPodium(
    first: _face(faces, places.$1),
    second: _face(faces, places.$2),
    third: _face(faces, places.$3),
  );
  if (podium.isEmpty) return null;
  return podium;
}

(String?, String?, String?)? _leaguePlaces(TournamentTableModel? table) {
  final rows = table?.standings
      .where((group) => group.groupLabel == null || group.groupLabel!.isEmpty)
      .map((group) => group.rows)
      .firstOrNull;
  final ranked = rows ?? table?.standings.firstOrNull?.rows;
  if (ranked == null || ranked.isEmpty) return null;
  return (
    _idAt(ranked, 0),
    _idAt(ranked, 1),
    _idAt(ranked, 2),
  );
}

(String?, String?, String?)? _knockoutPlaces(
  List<TournamentFixtureModel> fixtures,
) {
  final knockout = fixtures.where((fixture) => fixture.stage == 'knockout');
  if (knockout.isEmpty) return null;
  var finalRound = 0;
  for (final fixture in knockout) {
    if (fixture.round > finalRound) finalRound = fixture.round;
  }
  final finalMatch = knockout
      .where((fixture) => fixture.round == finalRound)
      .firstOrNull;
  if (finalMatch == null) return null;
  final championId = finalMatch.decidedWinnerId;
  if (championId == null) return null;
  final runnerUpId = _opponentId(finalMatch, championId);
  String? thirdId;
  if (finalRound > 1) {
    for (final semi in knockout.where((fixture) => fixture.round == finalRound - 1)) {
      if (semi.decidedWinnerId != championId) continue;
      thirdId = _opponentId(semi, championId);
      break;
    }
  }
  return (championId, runnerUpId, thirdId);
}

String? _idAt(List<StandingRowModel> rows, int index) {
  if (index >= rows.length) return null;
  final id = rows[index].teamId;
  if (id.isEmpty) return null;
  return id;
}

String? _opponentId(TournamentFixtureModel fixture, String teamId) {
  if (fixture.fromTeamId == teamId && fixture.toTeamId.isNotEmpty) {
    return fixture.toTeamId;
  }
  if (fixture.toTeamId == teamId && fixture.fromTeamId.isNotEmpty) {
    return fixture.fromTeamId;
  }
  return null;
}

TournamentPodiumTeam? _face(Map<String, TournamentPodiumTeam> faces, String? id) {
  if (id == null || id.isEmpty) return null;
  return faces[id] ?? TournamentPodiumTeam(id: id, name: 'Team');
}

Map<String, TournamentPodiumTeam> _teamFaces(
  List<TournamentFixtureModel> fixtures,
  List<TournamentEntryModel> entries,
  TournamentTableModel? table,
) {
  final faces = <String, TournamentPodiumTeam>{};
  void remember(String id, String? name, String? logo) {
    if (id.isEmpty) return;
    final current = faces[id];
    final nextName = _usableName(name) ?? current?.name ?? 'Team';
    final nextLogo = (logo != null && logo.isNotEmpty) ? logo : (current?.logo ?? '');
    faces[id] = TournamentPodiumTeam(id: id, name: nextName, logo: nextLogo);
  }

  for (final entry in entries) {
    remember(entry.teamId, entry.teamName, entry.teamLogo);
  }
  for (final group in table?.standings ?? const <StandingGroupModel>[]) {
    for (final row in group.rows) {
      remember(row.teamId, row.teamName, null);
    }
  }
  for (final fixture in fixtures) {
    _rememberSide(remember, fixture.match.fromTeamHelper);
    _rememberSide(remember, fixture.match.toTeamHelper);
    _rememberSide(remember, fixture.match.winnerTeamHelper);
  }
  return faces;
}

void _rememberSide(
  void Function(String id, String? name, String? logo) remember,
  TeamRefFieldInstance side,
) {
  final id = side.getId();
  if (id == null || id.isEmpty) return;
  final subset = side.getSubsetModel();
  remember(id, subset?.name, subset?.logo);
}

String? _usableName(String? name) {
  final text = name?.trim();
  if (text == null || text.isEmpty || text == 'Team') return null;
  return text;
}
