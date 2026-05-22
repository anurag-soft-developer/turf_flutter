import '../../../../core/models/user_field_instance.dart';
import '../../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../../match_up/model/team_match_model.dart';
import '../../../../scoring/cricket/model/cricket_ball_event_model.dart';
import '../cricket_lineup_card.dart';

class CricketBatsmanScorecardRow {
  const CricketBatsmanScorecardRow({
    required this.userId,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.isOut,
    required this.isOnCrease,
    this.dismissalText,
  });

  final String userId;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final bool isOnCrease;
  final String? dismissalText;

  double get strikeRate => balls > 0 ? (runs / balls) * 100 : 0;
}

class CricketBowlerScorecardRow {
  const CricketBowlerScorecardRow({
    required this.userId,
    required this.legalBalls,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.isCurrentBowler,
  });

  final String userId;
  final int legalBalls;
  final int maidens;
  final int runs;
  final int wickets;
  final bool isCurrentBowler;

  String get oversLabel => _oversFromBalls(legalBalls);

  double get economy =>
      legalBalls > 0 ? runs / (legalBalls / 6) : 0;
}

class CricketInningsExtras {
  const CricketInningsExtras({
    required this.total,
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
  });

  final int total;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
}

class CricketFallOfWicket {
  const CricketFallOfWicket({
    required this.score,
    required this.wicketNumber,
    required this.batsmanUserId,
    required this.legalBalls,
  });

  final int score;
  final int wicketNumber;
  final String batsmanUserId;
  final int legalBalls;
}

class CricketTeamInningsScorecard {
  const CricketTeamInningsScorecard({
    required this.innings,
    required this.runs,
    required this.wickets,
    required this.legalBalls,
    required this.maxOvers,
    required this.extras,
    required this.batsmen,
    required this.yetToBatUserIds,
    required this.fallOfWickets,
    required this.bowlers,
  });

  final int innings;
  final int runs;
  final int wickets;
  final int legalBalls;
  final int maxOvers;
  final CricketInningsExtras extras;
  final List<CricketBatsmanScorecardRow> batsmen;
  final List<String> yetToBatUserIds;
  final List<CricketFallOfWicket> fallOfWickets;
  final List<CricketBowlerScorecardRow> bowlers;

  String get totalOversLabel => _oversFromBalls(legalBalls);
}

String _oversFromBalls(int balls) => '${balls ~/ 6}.${balls % 6}';

String? battingTeamIdForInnings(TeamMatchModel match, int innings) {
  final cs = match.cricketState;
  if (cs == null || innings < 1) return null;

  final currentBattingId = cs.battingTeamHelper.getId();
  if (currentBattingId == null || currentBattingId.isEmpty) return null;
  if (innings == cs.currentInnings) return currentBattingId;

  final fromId = match.fromTeamHelper.getId() ?? '';
  final toId = match.toTeamHelper.getId() ?? '';
  final otherId = currentBattingId == fromId ? toId : fromId;
  if (otherId.isEmpty) return null;

  return cs.currentInnings.isOdd == innings.isOdd
      ? currentBattingId
      : otherId;
}

List<int> inningsForBattingTeam(TeamMatchModel match, String teamId) {
  final cs = match.cricketState;
  if (cs == null || teamId.isEmpty) return const [];

  final innings = <int>[];
  for (var i = 1; i <= cs.inningsSummaries.length; i++) {
    if (battingTeamIdForInnings(match, i) == teamId) {
      innings.add(i);
    }
  }
  return innings;
}

CricketTeamInningsScorecard? buildTeamInningsScorecard({
  required TeamMatchModel match,
  required List<CricketOverEvent> overs,
  required String battingTeamId,
  required int innings,
}) {
  final cs = match.cricketState;
  if (cs == null || innings < 1 || innings > cs.inningsSummaries.length) {
    return null;
  }

  final summary = cs.inningsSummaries[innings - 1];
  final inningsOvers = overs.where((over) => over.innings == innings).toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));

  final battingXi = playingXiForTeam(match, battingTeamId);

  final strikerId = innings == cs.currentInnings
      ? cs.strikerUserHelper.getId()
      : null;
  final nonStrikerId = innings == cs.currentInnings
      ? cs.nonStrikerUserHelper.getId()
      : null;
  final currentBowlerId = innings == cs.currentInnings
      ? cs.bowlerUserHelper.getId()
      : null;

  final dismissed = dismissedBatsmanUserIds(overs, innings);
  final battingStats = <String, _BattingAccumulator>{};
  final hasBatted = <String>{};
  final fallOfWickets = <CricketFallOfWicket>[];
  final battingOrder = <String, int>{};
  final extras = _InningsExtrasAccumulator();
  var runningScore = 0;
  var legalBalls = 0;
  var battingOrderCounter = 0;

  for (final over in inningsOvers) {
    for (final ball in over.ballEvents) {
      runningScore += ball.totalRunsOnDelivery;
      extras.add(ball);
      if (ball.isLegalDelivery) {
        legalBalls += 1;
      }

      final striker = UserFieldInstance(ball.strikerUserId).getId();
      if (striker != null && striker.isNotEmpty) {
        hasBatted.add(striker);
        battingOrder.putIfAbsent(striker, () => battingOrderCounter++);
        final acc = battingStats.putIfAbsent(striker, _BattingAccumulator.new);
        acc.runs += ball.runsOffBat;
        if (ball.isLegalDelivery) {
          acc.balls += 1;
        }
        if (ball.runsOffBat == 4) acc.fours += 1;
        if (ball.runsOffBat == 6) acc.sixes += 1;
      }

      if (ball.isWicket && ball.wicketsFallen > 0) {
        final outId = UserFieldInstance(ball.dismissedUserId).getId();
        if (outId != null && outId.isNotEmpty) {
          hasBatted.add(outId);
          battingOrder.putIfAbsent(outId, () => battingOrderCounter++);
          fallOfWickets.add(
            CricketFallOfWicket(
              score: runningScore,
              wicketNumber: ball.wicketsFallen,
              batsmanUserId: outId,
              legalBalls: legalBalls,
            ),
          );
        }
      }
    }
  }

  if (strikerId != null && strikerId.isNotEmpty) hasBatted.add(strikerId);
  if (nonStrikerId != null && nonStrikerId.isNotEmpty) {
    hasBatted.add(nonStrikerId);
  }

  final batsmenRows = <CricketBatsmanScorecardRow>[];
  for (final userId in hasBatted) {
    final acc = battingStats[userId] ?? _BattingAccumulator();
    final isOut = dismissed.contains(userId);
    batsmenRows.add(
      CricketBatsmanScorecardRow(
        userId: userId,
        runs: acc.runs,
        balls: acc.balls,
        fours: acc.fours,
        sixes: acc.sixes,
        isOut: isOut,
        isOnCrease:
            !isOut &&
            (userId == strikerId || userId == nonStrikerId) &&
            innings == cs.currentInnings,
        dismissalText: isOut
            ? _dismissalTextForBatsman(inningsOvers, userId)
            : null,
      ),
    );
  }

  batsmenRows.sort((a, b) {
    final aOrder = battingOrder[a.userId] ?? 1 << 20;
    final bOrder = battingOrder[b.userId] ?? 1 << 20;
    return aOrder.compareTo(bOrder);
  });

  final yetToBat = battingXi
      .map((player) => player.userIdHelper.getId())
      .whereType<String>()
      .where((id) => id.isNotEmpty && !hasBatted.contains(id))
      .toList();

  final bowlers = _buildBowlingRows(
    inningsOvers: inningsOvers,
    currentBowlerId: currentBowlerId,
    innings: innings,
    currentInnings: cs.currentInnings,
  );

  return CricketTeamInningsScorecard(
    innings: innings,
    runs: summary.runs,
    wickets: summary.wickets,
    legalBalls: summary.legalBalls,
    maxOvers: cs.maxOvers,
    extras: extras.toModel(),
    batsmen: batsmenRows,
    yetToBatUserIds: yetToBat,
    fallOfWickets: fallOfWickets,
    bowlers: bowlers,
  );
}

class _BattingAccumulator {
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
}

class _InningsExtrasAccumulator {
  int wides = 0;
  int noBalls = 0;
  int byes = 0;
  int legByes = 0;

  void add(CricketBallEvent ball) {
    wides += ball.extrasWide;
    if (ball.extrasNoBall) noBalls += 1;
    byes += ball.extrasBye;
    legByes += ball.extrasLegBye;
  }

  CricketInningsExtras toModel() {
    final total = wides + noBalls + byes + legByes;
    return CricketInningsExtras(
      total: total,
      wides: wides,
      noBalls: noBalls,
      byes: byes,
      legByes: legByes,
    );
  }
}

String? _dismissalTextForBatsman(
  List<CricketOverEvent> overs,
  String batsmanUserId,
) {
  for (final over in overs) {
    for (final ball in over.ballEvents) {
      if (!ball.isWicket) continue;
      final dismissed = UserFieldInstance(ball.dismissedUserId).getId();
      if (dismissed != batsmanUserId) continue;

      final bowler = _playerName(over.bowlerUserId);
      final fielder = _playerName(ball.primaryFielderUserId);
      return switch (ball.wicketKind) {
        CricketWicketKind.caught => 'c $fielder b $bowler',
        CricketWicketKind.bowled => 'b $bowler',
        CricketWicketKind.lbw => 'lbw b $bowler',
        CricketWicketKind.runOut => fielder.isEmpty
            ? 'run out'
            : 'run out ($fielder)',
        CricketWicketKind.stumped => 'st $fielder b $bowler',
        CricketWicketKind.hitWicket => 'hit wicket b $bowler',
        CricketWicketKind.other => 'out',
        null => 'out',
      };
    }
  }
  return 'out';
}

String _playerName(dynamic userField) {
  final helper = UserFieldInstance(userField);
  return helper.getName() ?? helper.getDisplayName();
}

List<CricketBowlerScorecardRow> _buildBowlingRows({
  required List<CricketOverEvent> inningsOvers,
  required String? currentBowlerId,
  required int innings,
  required int currentInnings,
}) {
  final byBowler = <String, _BowlingAccumulator>{};

  for (final over in inningsOvers) {
    final bowlerId = UserFieldInstance(over.bowlerUserId).getId();
    if (bowlerId == null || bowlerId.isEmpty) continue;
    final acc = byBowler.putIfAbsent(bowlerId, _BowlingAccumulator.new);
    var legalInOver = 0;
    var runsInOver = 0;
    for (final ball in over.ballEvents) {
      runsInOver += ball.totalRunsOnDelivery;
      if (ball.isLegalDelivery) {
        acc.legalBalls += 1;
        legalInOver += 1;
      }
      if (ball.isWicket &&
          ball.wicketKind != CricketWicketKind.runOut &&
          ball.wicketsFallen > 0) {
        acc.wickets += ball.wicketsFallen;
      }
    }
    acc.runs += runsInOver;
    if (legalInOver == 6 && runsInOver == 0) {
      acc.maidens += 1;
    }
  }

  final rows = byBowler.entries
      .map(
        (entry) => CricketBowlerScorecardRow(
          userId: entry.key,
          legalBalls: entry.value.legalBalls,
          maidens: entry.value.maidens,
          runs: entry.value.runs,
          wickets: entry.value.wickets,
          isCurrentBowler:
              innings == currentInnings && entry.key == currentBowlerId,
        ),
      )
      .toList()
    ..sort((a, b) => b.legalBalls.compareTo(a.legalBalls));

  return rows;
}

class _BowlingAccumulator {
  int legalBalls = 0;
  int maidens = 0;
  int runs = 0;
  int wickets = 0;
}

String playerDisplayName(TeamMatchModel match, String userId) {
  return announcedPlayerForUserId(match, userId)?.name ??
      UserFieldInstance(userId).getDisplayName();
}

String? playerAvatar(TeamMatchModel match, String userId) {
  return announcedPlayerForUserId(match, userId)?.avatar;
}

String playerNameSuffix(AnnouncedPlayerModel? player) {
  if (player == null) return '';
  final tags = <String>[];
  if (player.role == AnnouncedPlayerRole.wicketKeeper) tags.add('Wk');
  if (player.isCaption) tags.add('C');
  if (tags.isEmpty) return '';
  return ' (${tags.join(', ')})';
}
