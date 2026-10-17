import '../../core/models/user/user_model.dart';
import '../../engagement/engagement_entity.dart';
import '../../match_up/model/team_match_model.dart';
import '../../openings/model/opening_model.dart';
import '../../team/model/team_model.dart';
import '../../tournament/model/tournament_models.dart';
import 'content_post_model.dart';

sealed class ExploreItem {
  const ExploreItem();

  factory ExploreItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'];
    if (type == null || data is! Map<String, dynamic>) {
      throw FormatException('Invalid explore item payload');
    }

    return switch (type) {
      'tournament' => ExploreTournamentItem.fromExploreData(data),
      'match' => ExploreMatchItem(TeamMatchModel.fromJson(data)),
      'team' => ExploreTeamItem(TeamModel.fromJson(data)),
      'player' => ExplorePlayerItem(UserModel.fromJson(data)),
      'post' => ExplorePostItem(ContentPostModel.fromJson(data)),
      'opening' => ExploreOpeningItem(OpeningModel.fromJson(data)),
      _ => throw FormatException('Unknown explore item type: $type'),
    };
  }

  String? get entityId => switch (this) {
    ExploreTournamentItem(:final tournament) => tournament.id,
    ExploreMatchItem(:final match) => match.id,
    ExploreTeamItem(:final team) => team.id,
    ExplorePlayerItem(:final player) => player.id,
    ExplorePostItem(:final post) => post.id,
    ExploreOpeningItem(:final opening) => opening.id,
  };

  String get kind => switch (this) {
    ExploreTournamentItem() => 'tournament',
    ExploreMatchItem() => 'match',
    ExploreTeamItem() => 'team',
    ExplorePlayerItem() => 'player',
    ExplorePostItem() => 'post',
    ExploreOpeningItem() => 'opening',
  };

  /// Null for openings and tournaments. Like and impression stats stay on posts, matches, teams, and players.
  EngagementEntityType? get engagementType => switch (this) {
    ExploreTournamentItem() => null,
    ExploreMatchItem() => EngagementEntityType.match,
    ExploreTeamItem() => EngagementEntityType.team,
    ExplorePlayerItem() => EngagementEntityType.player,
    ExplorePostItem() => EngagementEntityType.post,
    ExploreOpeningItem() => null,
  };
}

class ExploreTournamentItem extends ExploreItem {
  const ExploreTournamentItem({required this.tournament, this.opening});

  final TournamentModel tournament;
  final OpeningModel? opening;

  factory ExploreTournamentItem.fromExploreData(Map<String, dynamic> data) {
    final rawOpening = data['opening'];
    return ExploreTournamentItem(
      tournament: TournamentModel.fromJson(data),
      opening: rawOpening is Map<String, dynamic>
          ? OpeningModel.fromJson(rawOpening)
          : rawOpening is Map
          ? OpeningModel.fromJson(Map<String, dynamic>.from(rawOpening))
          : null,
    );
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

class ExplorePostItem extends ExploreItem {
  const ExplorePostItem(this.post);

  final ContentPostModel post;
}

class ExploreOpeningItem extends ExploreItem {
  const ExploreOpeningItem(this.opening);

  final OpeningModel opening;
}

class ExplorePaginatedResponse {
  const ExplorePaginatedResponse({
    required this.data,
    required this.totalDocuments,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<ExploreItem> data;
  final int totalDocuments;
  final int page;
  final int limit;
  final int totalPages;

  factory ExplorePaginatedResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
              .whereType<Map<String, dynamic>>()
              .map(ExploreItem.fromJson)
              .toList()
        : <ExploreItem>[];

    return ExplorePaginatedResponse(
      data: items,
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasNextPage => data.isNotEmpty && page < totalPages;
  bool get isEmpty => data.isEmpty;
}
