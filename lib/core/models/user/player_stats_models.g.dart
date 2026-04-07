// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FootballPlayerStats _$FootballPlayerStatsFromJson(Map<String, dynamic> json) =>
    FootballPlayerStats(
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      matchesWon: (json['matchesWon'] as num?)?.toInt() ?? 0,
      goalsScored: (json['goalsScored'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      cleanSheets: (json['cleanSheets'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
      hatTricks: (json['hatTricks'] as num?)?.toInt() ?? 0,
      shotsOnTarget: (json['shotsOnTarget'] as num?)?.toInt() ?? 0,
      penaltiesScored: (json['penaltiesScored'] as num?)?.toInt() ?? 0,
      penaltiesMissed: (json['penaltiesMissed'] as num?)?.toInt() ?? 0,
      ownGoals: (json['ownGoals'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FootballPlayerStatsToJson(
  FootballPlayerStats instance,
) => <String, dynamic>{
  'matchesPlayed': instance.matchesPlayed,
  'matchesWon': instance.matchesWon,
  'goalsScored': instance.goalsScored,
  'assists': instance.assists,
  'cleanSheets': instance.cleanSheets,
  'saves': instance.saves,
  'yellowCards': instance.yellowCards,
  'redCards': instance.redCards,
  'hatTricks': instance.hatTricks,
  'shotsOnTarget': instance.shotsOnTarget,
  'penaltiesScored': instance.penaltiesScored,
  'penaltiesMissed': instance.penaltiesMissed,
  'ownGoals': instance.ownGoals,
};

CricketBattingStats _$CricketBattingStatsFromJson(Map<String, dynamic> json) =>
    CricketBattingStats(
      innings: (json['innings'] as num?)?.toInt() ?? 0,
      timesOut: (json['timesOut'] as num?)?.toInt() ?? 0,
      runsScored: (json['runsScored'] as num?)?.toInt() ?? 0,
      ballsFaced: (json['ballsFaced'] as num?)?.toInt() ?? 0,
      highestScore: (json['highestScore'] as num?)?.toInt() ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      strikeRate: (json['strikeRate'] as num?)?.toDouble() ?? 0.0,
      fours: (json['fours'] as num?)?.toInt() ?? 0,
      sixes: (json['sixes'] as num?)?.toInt() ?? 0,
      ducks: (json['ducks'] as num?)?.toInt() ?? 0,
      fifties: (json['fifties'] as num?)?.toInt() ?? 0,
      hundreds: (json['hundreds'] as num?)?.toInt() ?? 0,
      hatTrickSixes: (json['hatTrickSixes'] as num?)?.toInt() ?? 0,
      hatTrickFours: (json['hatTrickFours'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CricketBattingStatsToJson(
  CricketBattingStats instance,
) => <String, dynamic>{
  'innings': instance.innings,
  'timesOut': instance.timesOut,
  'runsScored': instance.runsScored,
  'ballsFaced': instance.ballsFaced,
  'highestScore': instance.highestScore,
  'average': instance.average,
  'strikeRate': instance.strikeRate,
  'fours': instance.fours,
  'sixes': instance.sixes,
  'ducks': instance.ducks,
  'fifties': instance.fifties,
  'hundreds': instance.hundreds,
  'hatTrickSixes': instance.hatTrickSixes,
  'hatTrickFours': instance.hatTrickFours,
};

CricketBowlingStats _$CricketBowlingStatsFromJson(Map<String, dynamic> json) =>
    CricketBowlingStats(
      oversBowled: (json['oversBowled'] as num?)?.toInt() ?? 0,
      ballsInCurrentOver: (json['ballsInCurrentOver'] as num?)?.toInt() ?? 0,
      maidenOvers: (json['maidenOvers'] as num?)?.toInt() ?? 0,
      wicketsTaken: (json['wicketsTaken'] as num?)?.toInt() ?? 0,
      runsConceded: (json['runsConceded'] as num?)?.toInt() ?? 0,
      bestFiguresWickets: (json['bestFiguresWickets'] as num?)?.toInt() ?? 0,
      bestFiguresRuns: (json['bestFiguresRuns'] as num?)?.toInt() ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      economy: (json['economy'] as num?)?.toDouble() ?? 0.0,
      strikeRate: (json['strikeRate'] as num?)?.toDouble() ?? 0.0,
      hatTricks: (json['hatTricks'] as num?)?.toInt() ?? 0,
      fiveWicketHauls: (json['fiveWicketHauls'] as num?)?.toInt() ?? 0,
      wides: (json['wides'] as num?)?.toInt() ?? 0,
      noBalls: (json['noBalls'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CricketBowlingStatsToJson(
  CricketBowlingStats instance,
) => <String, dynamic>{
  'oversBowled': instance.oversBowled,
  'ballsInCurrentOver': instance.ballsInCurrentOver,
  'maidenOvers': instance.maidenOvers,
  'wicketsTaken': instance.wicketsTaken,
  'runsConceded': instance.runsConceded,
  'bestFiguresWickets': instance.bestFiguresWickets,
  'bestFiguresRuns': instance.bestFiguresRuns,
  'average': instance.average,
  'economy': instance.economy,
  'strikeRate': instance.strikeRate,
  'hatTricks': instance.hatTricks,
  'fiveWicketHauls': instance.fiveWicketHauls,
  'wides': instance.wides,
  'noBalls': instance.noBalls,
};

CricketFieldingStats _$CricketFieldingStatsFromJson(
  Map<String, dynamic> json,
) => CricketFieldingStats(
  catches: (json['catches'] as num?)?.toInt() ?? 0,
  runOuts: (json['runOuts'] as num?)?.toInt() ?? 0,
  stumpings: (json['stumpings'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CricketFieldingStatsToJson(
  CricketFieldingStats instance,
) => <String, dynamic>{
  'catches': instance.catches,
  'runOuts': instance.runOuts,
  'stumpings': instance.stumpings,
};

CricketPlayerStats _$CricketPlayerStatsFromJson(Map<String, dynamic> json) =>
    CricketPlayerStats(
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      batting: json['batting'] == null
          ? const CricketBattingStats()
          : _battingFromJson(json['batting']),
      bowling: json['bowling'] == null
          ? const CricketBowlingStats()
          : _bowlingFromJson(json['bowling']),
      fielding: json['fielding'] == null
          ? const CricketFieldingStats()
          : _fieldingFromJson(json['fielding']),
    );

Map<String, dynamic> _$CricketPlayerStatsToJson(CricketPlayerStats instance) =>
    <String, dynamic>{
      'matchesPlayed': instance.matchesPlayed,
      'batting': instance.batting.toJson(),
      'bowling': instance.bowling.toJson(),
      'fielding': instance.fielding.toJson(),
    };

EarnedBadge _$EarnedBadgeFromJson(Map<String, dynamic> json) => EarnedBadge(
  badgeId: json['badgeId'] as String,
  earnedAt: DateTime.parse(json['earnedAt'] as String),
  sportType: json['sportType'] as String?,
);

Map<String, dynamic> _$EarnedBadgeToJson(EarnedBadge instance) =>
    <String, dynamic>{
      'badgeId': instance.badgeId,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'sportType': instance.sportType,
    };
