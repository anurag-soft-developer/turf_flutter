import 'package:flutter/material.dart';

import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../match_up/model/team_match_model.dart';
import '../model/football_match_event_model.dart';
import '../model/football_scoring_models.dart';

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

/// Fallback per-half length when [FootballStateModel.matchMinute] is unset.
const int footballDefaultHalfMinutes = 45;

bool isFootballRegulationPeriod(MatchFootballPeriod period) {
  return period == MatchFootballPeriod.firstHalf ||
      period == MatchFootballPeriod.secondHalf;
}

int? footballMatchDurationMs(FootballStateModel fs) {
  final mm = fs.matchMinute;
  if (mm == null || mm <= 0) return null;
  return mm * 60 * 1000;
}

int footballHalfDurationMs(FootballStateModel fs) {
  final total = footballMatchDurationMs(fs);
  if (total != null) return total ~/ 2;
  return footballDefaultHalfMinutes * 60 * 1000;
}

int footballTimerElapsedMs(FootballStateModel fs, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  var elapsed = fs.timerElapsedMs;
  if (!fs.isTimerPaused && fs.timerStartedAt != null) {
    elapsed += clock.difference(fs.timerStartedAt!).inMilliseconds;
  }
  return elapsed;
}

/// Sum of completed innings plus the current innings clock.
int footballTotalTimerElapsedMs(FootballStateModel fs, [DateTime? now]) {
  return fs.totalTimerElapsedMs + footballTimerElapsedMs(fs, now);
}

bool isFootballScoreTied(FootballStateModel fs) =>
    fs.scoreTeamOne == fs.scoreTeamTwo;

/// Regulation halves: 1st auto-stops at half duration; 2nd at full [matchMinute].
bool isFootballRegulationTimerReached(
  FootballStateModel fs, [
  DateTime? now,
]) {
  if (!isFootballRegulationPeriod(fs.currentPeriod)) return true;

  final halfMs = footballHalfDurationMs(fs);
  final totalMs = footballMatchDurationMs(fs);
  final inningMs = footballTimerElapsedMs(fs, now);

  if (fs.currentPeriod == MatchFootballPeriod.firstHalf) {
    return inningMs >= halfMs;
  }
  if (fs.currentPeriod == MatchFootballPeriod.secondHalf) {
    if (totalMs != null) {
      return footballTotalTimerElapsedMs(fs, now) >= totalMs;
    }
    return inningMs >= halfMs;
  }
  return false;
}

bool shouldAutoPauseFootballTimer(FootballStateModel fs, [DateTime? now]) {
  if (fs.isTimerPaused) return false;
  if (!isFootballRegulationPeriod(fs.currentPeriod)) return false;
  return isFootballRegulationTimerReached(fs, now);
}

bool shouldShowFootballStartNextInning(
  FootballStateModel fs, [
  DateTime? now,
]) {
  if (fs.currentInnings >= fs.inningsSummaries.length) return false;
  if (!isFootballRegulationTimerReached(fs, now) &&
      isFootballRegulationPeriod(fs.currentPeriod)) {
    return false;
  }
  if (!isFootballRegulationPeriod(fs.currentPeriod)) {
    return true;
  }
  if (fs.currentInnings >= 2 && !isFootballScoreTied(fs)) return false;
  return true;
}

bool canEndFootballMatch(FootballStateModel fs) =>
    fs.currentInnings >= fs.inningsSummaries.length;

String formatFootballTimer(int elapsedMs) {
  final totalSeconds = elapsedMs ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String footballInningsTimerLabel(FootballStateModel fs) {
  return switch (fs.currentPeriod) {
    MatchFootballPeriod.firstHalf => '1st half timer',
    MatchFootballPeriod.secondHalf => '2nd half timer',
    MatchFootballPeriod.extraFirst => 'Extra time (1st) timer',
    MatchFootballPeriod.extraSecond => 'Extra time (2nd) timer',
    MatchFootballPeriod.penalties => 'Penalties timer',
  };
}

String inningsLabel(int innings, {MatchFootballPeriod? period}) {
  if (period != null) {
    return 'Innings $innings · ${periodLabel(period)}';
  }
  return 'Innings $innings';
}

FootballInningsSummaryModel? inningsSummaryAt(
  FootballStateModel fs,
  int innings,
) {
  if (innings < 1 || innings > fs.inningsSummaries.length) {
    return null;
  }
  return fs.inningsSummaries[innings - 1];
}
