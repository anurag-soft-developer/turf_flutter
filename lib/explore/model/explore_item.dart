import '../../core/models/user/user_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/model/team_model.dart';

sealed class ExploreItem {
  const ExploreItem();

  factory ExploreItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'];
    if (type == null || data is! Map<String, dynamic>) {
      throw FormatException('Invalid explore item payload');
    }

    return switch (type) {
      'match' => ExploreMatchItem(TeamMatchModel.fromJson(data)),
      'team' => ExploreTeamItem(TeamModel.fromJson(data)),
      'player' => ExplorePlayerItem(UserModel.fromJson(data)),
      'team_row' => ExploreTeamRowItem.fromData(data),
      'player_row' => ExplorePlayerRowItem.fromData(data),
      _ => throw FormatException('Unknown explore item type: $type'),
    };
  }
}

class ExploreMatchItem extends ExploreItem {
  const ExploreMatchItem(this.match);

  final TeamMatchModel match;
}

class ExploreTeamItem extends ExploreItem {
  const ExploreTeamItem(this.team);

  final TeamModel team;
}

class ExplorePlayerItem extends ExploreItem {
  const ExplorePlayerItem(this.player);

  final UserModel player;
}

class ExploreTeamRowItem extends ExploreItem {
  const ExploreTeamRowItem({
    required this.title,
    required this.reason,
    required this.items,
  });

  final String title;
  final String reason;
  final List<TeamModel> items;

  factory ExploreTeamRowItem.fromData(Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(TeamModel.fromJson)
            .toList()
        : <TeamModel>[];

    return ExploreTeamRowItem(
      title: data['title'] as String? ?? 'Teams to explore',
      reason: data['reason'] as String? ?? '',
      items: items,
    );
  }
}

class ExplorePlayerRowItem extends ExploreItem {
  const ExplorePlayerRowItem({
    required this.title,
    required this.reason,
    required this.items,
  });

  final String title;
  final String reason;
  final List<UserModel> items;

  factory ExplorePlayerRowItem.fromData(Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList()
        : <UserModel>[];

    return ExplorePlayerRowItem(
      title: data['title'] as String? ?? 'Players to follow',
      reason: data['reason'] as String? ?? '',
      items: items,
    );
  }
}

class ExploreCounts {
  const ExploreCounts({
    required this.match,
    required this.team,
    required this.player,
  });

  final int match;
  final int team;
  final int player;

  factory ExploreCounts.fromJson(Map<String, dynamic> json) {
    return ExploreCounts(
      match: (json['match'] as num?)?.toInt() ?? 0,
      team: (json['team'] as num?)?.toInt() ?? 0,
      player: (json['player'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExplorePaginatedResponse {
  const ExplorePaginatedResponse({
    required this.data,
    required this.totalDocuments,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.counts,
  });

  final List<ExploreItem> data;
  final int totalDocuments;
  final int page;
  final int limit;
  final int totalPages;
  final ExploreCounts? counts;

  factory ExplorePaginatedResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(ExploreItem.fromJson)
            .toList()
        : <ExploreItem>[];

    ExploreCounts? counts;
    final meta = json['meta'];
    if (meta is Map<String, dynamic>) {
      final rawCounts = meta['counts'];
      if (rawCounts is Map<String, dynamic>) {
        counts = ExploreCounts.fromJson(rawCounts);
      }
    }

    return ExplorePaginatedResponse(
      data: items,
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      counts: counts,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get isEmpty => data.isEmpty;
}
