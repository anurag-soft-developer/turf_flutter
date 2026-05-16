import 'package:json_annotation/json_annotation.dart';

import 'team_model.dart';

part 'team_leaderboard_model.g.dart';

@JsonSerializable()
class TeamLeaderboardStats {
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int matchesPlayed;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int wins;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int losses;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int draws;
  @JsonKey(fromJson: _doubleFromJson, defaultValue: 0.0)
  final double winRate;

  const TeamLeaderboardStats({
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0,
  });

  factory TeamLeaderboardStats.fromJson(Map<String, dynamic> json) =>
      _$TeamLeaderboardStatsFromJson(json);

  Map<String, dynamic> toJson() => _$TeamLeaderboardStatsToJson(this);
}

@JsonSerializable()
class TeamLeaderboardRow {
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int rank;
  final String id;
  final String name;
  @JsonKey(fromJson: _intFromJson, defaultValue: 0)
  final int points;
  final String? avatar;
  final TeamLeaderboardStats stats;

  const TeamLeaderboardRow({
    this.rank = 0,
    required this.id,
    required this.name,
    this.points = 0,
    this.avatar,
    this.stats = const TeamLeaderboardStats(),
  });

  factory TeamLeaderboardRow.fromJson(Map<String, dynamic> json) =>
      _$TeamLeaderboardRowFromJson(json);

  Map<String, dynamic> toJson() => _$TeamLeaderboardRowToJson(this);
}

class TeamLeaderboardQuery {
  final TeamSportType sportType;
  final int page;
  final int limit;

  const TeamLeaderboardQuery({
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
