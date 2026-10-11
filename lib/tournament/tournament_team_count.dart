const tournamentMinLeagueTeams = 3;
const tournamentMinHybridTeams = 4;
const tournamentMinKnockoutTeams = 4;

/// Common knockout sizes (organizer may use any power of two ≥ 4).
const knockoutTeamPresets = [4, 8, 16, 32, 64, 128];

bool isPowerOfTwo(int n) => n > 0 && (n & (n - 1)) == 0;

/// Largest power-of-two bracket (≥4) that fits [maxTeams].
int hybridKnockoutBracketSize(int maxTeams) {
  if (maxTeams < tournamentMinKnockoutTeams) return tournamentMinKnockoutTeams;
  var size = tournamentMinKnockoutTeams;
  while (size * 2 <= maxTeams) {
    size *= 2;
  }
  return size;
}

int minTeamsForFormat(String format) {
  return switch (format) {
    'league' => tournamentMinLeagueTeams,
    'hybrid' => tournamentMinHybridTeams,
    _ => tournamentMinKnockoutTeams,
  };
}

String inviteAtLeastTeamsMessage(String format) {
  final minTeams = minTeamsForFormat(format);
  return 'Invite at least $minTeams teams.';
}

String? validateTournamentTeamCount(String format, int maxTeams) {
  if (format == 'knockout') {
    if (maxTeams < tournamentMinKnockoutTeams) {
      return inviteAtLeastTeamsMessage(format);
    }
    if (!isPowerOfTwo(maxTeams)) {
      return 'Select 4, 8, 16, 32, or 64 teams.';
    }
    return null;
  }
  if (format == 'league') {
    if (maxTeams < tournamentMinLeagueTeams) {
      return inviteAtLeastTeamsMessage(format);
    }
    return null;
  }
  if (format == 'hybrid') {
    if (maxTeams < tournamentMinHybridTeams) {
      return inviteAtLeastTeamsMessage(format);
    }
    return null;
  }
  if (maxTeams < 1) {
    return inviteAtLeastTeamsMessage(format);
  }
  return null;
}

int leagueMatchCount(int teams) => teams < 2 ? 0 : teams * (teams - 1) ~/ 2;

String formatHelpTextForCreate(String format) {
  if (format == 'league') {
    return 'One round-robin for all teams. You choose how many teams when you lock the lineup.';
  }
  if (format == 'hybrid') {
    return 'League stage first, then a knockout for the top teams. '
        'Final team count is set when you lock the lineup.';
  }
  return 'Select 4, 8, 16, 32, or 64 teams.';
}

String formatHelpText(String format, int maxTeams) {
  if (format == 'league') {
    final matches = leagueMatchCount(maxTeams);
    final base = 'One round-robin for all teams. A win is worth 2 points.';
    if (maxTeams >= 16 && matches > 0) {
      return '$base About $matches league fixtures at full capacity.';
    }
    return base;
  }
  if (format == 'hybrid') {
    final ko = hybridKnockoutBracketSize(maxTeams);
    final leagueMatches = leagueMatchCount(maxTeams);
    return 'Round-robin league first ($leagueMatches fixtures at full capacity), '
        'then the top $ko teams enter a $ko-team knockout bracket.';
  }
  return 'Single elimination. Round 1 is drawn now; later rounds follow winners.';
}
