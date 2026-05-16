// GENERATED CODE - manually aligned with json_serializable output

part of 'team_leaderboard_model.dart';

TeamLeaderboardStats _$TeamLeaderboardStatsFromJson(Map<String, dynamic> json) =>
    TeamLeaderboardStats(
      matchesPlayed: json['matchesPlayed'] == null
          ? 0
          : _intFromJson(json['matchesPlayed']),
      wins: json['wins'] == null ? 0 : _intFromJson(json['wins']),
      losses: json['losses'] == null ? 0 : _intFromJson(json['losses']),
      draws: json['draws'] == null ? 0 : _intFromJson(json['draws']),
      winRate: json['winRate'] == null ? 0.0 : _doubleFromJson(json['winRate']),
    );

Map<String, dynamic> _$TeamLeaderboardStatsToJson(
  TeamLeaderboardStats instance,
) =>
    <String, dynamic>{
      'matchesPlayed': instance.matchesPlayed,
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'winRate': instance.winRate,
    };

TeamLeaderboardRow _$TeamLeaderboardRowFromJson(Map<String, dynamic> json) =>
    TeamLeaderboardRow(
      rank: json['rank'] == null ? 0 : _intFromJson(json['rank']),
      id: json['id'] as String,
      name: json['name'] as String,
      points: json['points'] == null ? 0 : _intFromJson(json['points']),
      avatar: json['avatar'] as String?,
      stats: json['stats'] == null
          ? const TeamLeaderboardStats()
          : TeamLeaderboardStats.fromJson(
              json['stats'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$TeamLeaderboardRowToJson(TeamLeaderboardRow instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'id': instance.id,
      'name': instance.name,
      'points': instance.points,
      'avatar': instance.avatar,
      'stats': instance.stats.toJson(),
    };
