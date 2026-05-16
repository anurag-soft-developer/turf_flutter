import 'package:json_annotation/json_annotation.dart';

import '../../core/models/user/player_stats_models.dart';

part 'player_leaderboard_model.g.dart';

@JsonSerializable()
class PlayerLeaderboardStats {
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int matchesPlayed;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int matchesWon;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int matchesLost;
  @JsonKey(fromJson: _doubleFromJson, defaultValue: 0.0)
  final double winRate;

  const PlayerLeaderboardStats({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.winRate = 0,
  });

  factory PlayerLeaderboardStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerLeaderboardStatsFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerLeaderboardStatsToJson(this);
}

@JsonSerializable()
class PlayerLeaderboardRow {
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int rank;
  final String id;
  final String name;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int points;
  final String? avatar;
  final PlayerLeaderboardStats stats;

  const PlayerLeaderboardRow({
    this.rank = 0,
    required this.id,
    required this.name,
    this.points = 0,
    this.avatar,
    this.stats = const PlayerLeaderboardStats(),
  });

  factory PlayerLeaderboardRow.fromJson(Map<String, dynamic> json) =>
      _$PlayerLeaderboardRowFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerLeaderboardRowToJson(this);
}

class PlayerLeaderboardQuery {
  final SportType sportType;
  final int page;
  final int limit;

  const PlayerLeaderboardQuery({
    required this.sportType,
    this.page = 1,
    this.limit = 50,
  });

  Map<String, dynamic> toQueryParameters() => {
        'sportType': sportType.name,
        'page': page,
        'limit': limit,
      };
}

int _intFromJson(dynamic json) {
  if (json is int) return json;
  if (json is num) return json.toInt();
  if (json is String) return int.tryParse(json) ?? 0;
  return 0;
}

double _doubleFromJson(dynamic json) {
  if (json is double) return json;
  if (json is int) return json.toDouble();
  if (json is num) return json.toDouble();
  if (json is String) return double.tryParse(json) ?? 0.0;
  return 0.0;
}
