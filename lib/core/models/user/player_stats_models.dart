import 'package:json_annotation/json_annotation.dart';

part 'player_stats_models.g.dart';

// ---------------------------------------------------------------------------
// Sport type
// ---------------------------------------------------------------------------

enum SportType {
  @JsonValue('cricket')
  cricket,
  @JsonValue('football')
  football,
}

// ---------------------------------------------------------------------------
// Football
// ---------------------------------------------------------------------------

@JsonSerializable()
class FootballPlayerStats {
  @JsonKey(defaultValue: 0)
  final int matchesPlayed;
  @JsonKey(defaultValue: 0)
  final int matchesWon;
  @JsonKey(defaultValue: 0)
  final int goalsScored;
  @JsonKey(defaultValue: 0)
  final int assists;
  @JsonKey(defaultValue: 0)
  final int cleanSheets;
  @JsonKey(defaultValue: 0)
  final int saves;
  @JsonKey(defaultValue: 0)
  final int yellowCards;
  @JsonKey(defaultValue: 0)
  final int redCards;
  @JsonKey(defaultValue: 0)
  final int hatTricks;
  @JsonKey(defaultValue: 0)
  final int shotsOnTarget;
  @JsonKey(defaultValue: 0)
  final int penaltiesScored;
  @JsonKey(defaultValue: 0)
  final int penaltiesMissed;
  @JsonKey(defaultValue: 0)
  final int ownGoals;

  const FootballPlayerStats({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.goalsScored = 0,
    this.assists = 0,
    this.cleanSheets = 0,
    this.saves = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.hatTricks = 0,
    this.shotsOnTarget = 0,
    this.penaltiesScored = 0,
    this.penaltiesMissed = 0,
    this.ownGoals = 0,
  });

  factory FootballPlayerStats.fromJson(Map<String, dynamic> json) =>
      _$FootballPlayerStatsFromJson(json);
  Map<String, dynamic> toJson() => _$FootballPlayerStatsToJson(this);
}

// ---------------------------------------------------------------------------
// Cricket — Batting
// ---------------------------------------------------------------------------

@JsonSerializable()
class CricketBattingStats {
  @JsonKey(defaultValue: 0)
  final int innings;
  @JsonKey(defaultValue: 0)
  final int timesOut;
  @JsonKey(defaultValue: 0)
  final int runsScored;
  @JsonKey(defaultValue: 0)
  final int ballsFaced;
  @JsonKey(defaultValue: 0)
  final int highestScore;
  @JsonKey(defaultValue: 0.0)
  final double average;
  @JsonKey(defaultValue: 0.0)
  final double strikeRate;
  @JsonKey(defaultValue: 0)
  final int fours;
  @JsonKey(defaultValue: 0)
  final int sixes;
  @JsonKey(defaultValue: 0)
  final int ducks;
  @JsonKey(defaultValue: 0)
  final int fifties;
  @JsonKey(defaultValue: 0)
  final int hundreds;
  @JsonKey(defaultValue: 0)
  final int hatTrickSixes;
  @JsonKey(defaultValue: 0)
  final int hatTrickFours;

  const CricketBattingStats({
    this.innings = 0,
    this.timesOut = 0,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.highestScore = 0,
    this.average = 0.0,
    this.strikeRate = 0.0,
    this.fours = 0,
    this.sixes = 0,
    this.ducks = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.hatTrickSixes = 0,
    this.hatTrickFours = 0,
  });

  factory CricketBattingStats.fromJson(Map<String, dynamic> json) =>
      _$CricketBattingStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CricketBattingStatsToJson(this);
}

// ---------------------------------------------------------------------------
// Cricket — Bowling
// ---------------------------------------------------------------------------

@JsonSerializable()
class CricketBowlingStats {
  @JsonKey(defaultValue: 0)
  final int oversBowled;
  @JsonKey(defaultValue: 0)
  final int ballsInCurrentOver;
  @JsonKey(defaultValue: 0)
  final int maidenOvers;
  @JsonKey(defaultValue: 0)
  final int wicketsTaken;
  @JsonKey(defaultValue: 0)
  final int runsConceded;
  @JsonKey(defaultValue: 0)
  final int bestFiguresWickets;
  @JsonKey(defaultValue: 0)
  final int bestFiguresRuns;
  @JsonKey(defaultValue: 0.0)
  final double average;
  @JsonKey(defaultValue: 0.0)
  final double economy;
  @JsonKey(defaultValue: 0.0)
  final double strikeRate;
  @JsonKey(defaultValue: 0)
  final int hatTricks;
  @JsonKey(defaultValue: 0)
  final int fiveWicketHauls;
  @JsonKey(defaultValue: 0)
  final int wides;
  @JsonKey(defaultValue: 0)
  final int noBalls;

  const CricketBowlingStats({
    this.oversBowled = 0,
    this.ballsInCurrentOver = 0,
    this.maidenOvers = 0,
    this.wicketsTaken = 0,
    this.runsConceded = 0,
    this.bestFiguresWickets = 0,
    this.bestFiguresRuns = 0,
    this.average = 0.0,
    this.economy = 0.0,
    this.strikeRate = 0.0,
    this.hatTricks = 0,
    this.fiveWicketHauls = 0,
    this.wides = 0,
    this.noBalls = 0,
  });

  factory CricketBowlingStats.fromJson(Map<String, dynamic> json) =>
      _$CricketBowlingStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CricketBowlingStatsToJson(this);
}

// ---------------------------------------------------------------------------
// Cricket — Fielding
// ---------------------------------------------------------------------------

@JsonSerializable()
class CricketFieldingStats {
  @JsonKey(defaultValue: 0)
  final int catches;
  @JsonKey(defaultValue: 0)
  final int runOuts;
  @JsonKey(defaultValue: 0)
  final int stumpings;

  const CricketFieldingStats({
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
  });

  factory CricketFieldingStats.fromJson(Map<String, dynamic> json) =>
      _$CricketFieldingStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CricketFieldingStatsToJson(this);
}

// ---------------------------------------------------------------------------
// Combined cricket player stats
// ---------------------------------------------------------------------------

CricketBattingStats _battingFromJson(dynamic json) =>
    json is Map<String, dynamic>
        ? CricketBattingStats.fromJson(json)
        : const CricketBattingStats();

CricketBowlingStats _bowlingFromJson(dynamic json) =>
    json is Map<String, dynamic>
        ? CricketBowlingStats.fromJson(json)
        : const CricketBowlingStats();

CricketFieldingStats _fieldingFromJson(dynamic json) =>
    json is Map<String, dynamic>
        ? CricketFieldingStats.fromJson(json)
        : const CricketFieldingStats();

@JsonSerializable(explicitToJson: true)
class CricketPlayerStats {
  @JsonKey(defaultValue: 0)
  final int matchesPlayed;
  @JsonKey(fromJson: _battingFromJson)
  final CricketBattingStats batting;
  @JsonKey(fromJson: _bowlingFromJson)
  final CricketBowlingStats bowling;
  @JsonKey(fromJson: _fieldingFromJson)
  final CricketFieldingStats fielding;

  const CricketPlayerStats({
    this.matchesPlayed = 0,
    this.batting = const CricketBattingStats(),
    this.bowling = const CricketBowlingStats(),
    this.fielding = const CricketFieldingStats(),
  });

  factory CricketPlayerStats.fromJson(Map<String, dynamic> json) =>
      _$CricketPlayerStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CricketPlayerStatsToJson(this);
}

// ---------------------------------------------------------------------------
// Player sport entry (polymorphic stats — manual serialization)
// ---------------------------------------------------------------------------

class PlayerSportEntry {
  final String sportType;
  final dynamic stats;

  const PlayerSportEntry({required this.sportType, this.stats});

  FootballPlayerStats? get footballStats =>
      stats is FootballPlayerStats ? stats as FootballPlayerStats : null;

  CricketPlayerStats? get cricketStats =>
      stats is CricketPlayerStats ? stats as CricketPlayerStats : null;

  factory PlayerSportEntry.fromJson(Map<String, dynamic> json) {
    final sportType = json['sportType'] as String;
    final rawStats = json['stats'];
    final statsMap =
        rawStats is Map<String, dynamic> ? rawStats : <String, dynamic>{};

    dynamic parsedStats;
    switch (sportType) {
      case 'football':
        parsedStats = FootballPlayerStats.fromJson(statsMap);
      case 'cricket':
        parsedStats = CricketPlayerStats.fromJson(statsMap);
      default:
        parsedStats = statsMap;
    }

    return PlayerSportEntry(sportType: sportType, stats: parsedStats);
  }

  Map<String, dynamic> toJson() {
    dynamic serializedStats;
    if (stats is FootballPlayerStats) {
      serializedStats = (stats as FootballPlayerStats).toJson();
    } else if (stats is CricketPlayerStats) {
      serializedStats = (stats as CricketPlayerStats).toJson();
    } else if (stats is Map) {
      serializedStats = stats;
    } else {
      serializedStats = {};
    }
    return {
      'sportType': sportType,
      'stats': serializedStats,
    };
  }
}

// ---------------------------------------------------------------------------
// Earned badge
// ---------------------------------------------------------------------------

@JsonSerializable()
class EarnedBadge {
  final String badgeId;
  final DateTime earnedAt;
  final String? sportType;

  const EarnedBadge({
    required this.badgeId,
    required this.earnedAt,
    this.sportType,
  });

  factory EarnedBadge.fromJson(Map<String, dynamic> json) =>
      _$EarnedBadgeFromJson(json);
  Map<String, dynamic> toJson() => _$EarnedBadgeToJson(this);
}
