// GENERATED CODE - manually aligned with json_serializable output

part of 'player_leaderboard_model.dart';

PlayerLeaderboardStats _$PlayerLeaderboardStatsFromJson(
  Map<String, dynamic> json,
) =>
    PlayerLeaderboardStats(
      matchesPlayed: json['matchesPlayed'] == null
          ? 0
          : _intFromJson(json['matchesPlayed']),
      matchesWon:
          json['matchesWon'] == null ? 0 : _intFromJson(json['matchesWon']),
      matchesLost:
          json['matchesLost'] == null ? 0 : _intFromJson(json['matchesLost']),
      winRate:
          json['winRate'] == null ? 0.0 : _doubleFromJson(json['winRate']),
    );

Map<String, dynamic> _$PlayerLeaderboardStatsToJson(
  PlayerLeaderboardStats instance,
) =>
    <String, dynamic>{
      'matchesPlayed': instance.matchesPlayed,
      'matchesWon': instance.matchesWon,
      'matchesLost': instance.matchesLost,
      'winRate': instance.winRate,
    };

PlayerLeaderboardRow _$PlayerLeaderboardRowFromJson(
  Map<String, dynamic> json,
) =>
    PlayerLeaderboardRow(
      rank: json['rank'] == null ? 0 : _intFromJson(json['rank']),
      id: json['id'] as String,
      name: json['name'] as String,
      points: json['points'] == null ? 0 : _intFromJson(json['points']),
      avatar: json['avatar'] as String?,
      stats: json['stats'] == null
          ? const PlayerLeaderboardStats()
          : PlayerLeaderboardStats.fromJson(
              json['stats'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PlayerLeaderboardRowToJson(
  PlayerLeaderboardRow instance,
) =>
    <String, dynamic>{
      'rank': instance.rank,
      'id': instance.id,
      'name': instance.name,
      'points': instance.points,
      'avatar': instance.avatar,
      'stats': instance.stats.toJson(),
    };
