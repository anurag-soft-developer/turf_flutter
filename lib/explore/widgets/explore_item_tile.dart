import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_history/match_card.dart';
import '../../components/match_up/team_logo.dart';
import '../../components/match_up/team_stats_row.dart';
import '../../components/player/follow/user_list_tile.dart';
import '../../core/config/constants.dart';
import '../../core/models/user_field_instance.dart';
import '../../engagement/engagement_entity.dart';
import '../../engagement/engagement_service.dart';
import '../../match_up/match_challenges/match_challenge_detail_screen.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/model/team_model.dart';
import '../model/content_post_model.dart';
import '../model/explore_item.dart';
import 'explore_like_button.dart';
import 'explore_post_viewer_screen.dart';

class ExploreItemTile extends StatelessWidget {
  const ExploreItemTile({super.key, required this.item});

  final ExploreItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      ExploreMatchItem(:final match) => _ExploreMatchTile(match: match),
      ExploreTeamItem(:final team) => _ExploreTeamTile(team: team),
      ExplorePlayerItem(:final player) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: UserListTile(
              helper: UserFieldInstance(player),
              onOpen: () {
                final id = player.id;
                if (id != null && id.isNotEmpty) {
                  EngagementService().trackView(
                    entityType: EngagementEntityType.player,
                    entityId: id,
                  );
                }
              },
            ),
          ),
        ),
      ExplorePostItem(:final post) => ExplorePostTile(post: post),
    };
  }
}

class _ExploreMatchTile extends StatelessWidget {
  const _ExploreMatchTile({required this.match});

  final TeamMatchModel match;

  @override
  Widget build(BuildContext context) {
    final isHistory =
        match.status == TeamMatchStatus.completed ||
        match.status == TeamMatchStatus.draw;

    return MatchCard(
      match: match,
      selectedTeamId: null,
      isHistory: isHistory,
      onTap: () async {
        final id = match.id;
        if (id != null && id.isNotEmpty) {
          EngagementService().trackView(
            entityType: EngagementEntityType.match,
            entityId: id,
          );
        }
        await openMatchChallengeDetail(match: match);
      },
    );
  }
}

class _ExploreTeamTile extends StatelessWidget {
  const _ExploreTeamTile({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = team.id;
          if (id != null && id.isNotEmpty) {
            EngagementService().trackView(
              entityType: EngagementEntityType.team,
              entityId: id,
            );
            Get.toNamed(
              AppConstants.routes.teamProfile,
              arguments: {'teamId': id},
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TeamLogo(url: team.logo, size: 48, teamId: team.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.textColor),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (team.location != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  team.location!.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(AppColors.textSecondaryColor),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TeamStatsRow.fromTeam(team, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class ExplorePostTile extends StatelessWidget {
  const ExplorePostTile({super.key, required this.post});

  final ContentPostModel post;

  @override
  Widget build(BuildContext context) {
    final author = post.postedByHelper;
    final teamName = post.teamHelper.getName();
    final media = post.primaryMedia;
    final match = post.match;
    final turfName = post.turfHelper.getName();
    final id = post.id ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = post.id;
          if (id != null && id.isNotEmpty) {
            openExplorePostViewer(id: id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: (author.getAvatar() ?? '').isNotEmpty
                        ? NetworkImage(author.getAvatar()!)
                        : null,
                    child: (author.getAvatar() ?? '').isEmpty
                        ? Text(
                            author.getDisplayName().isNotEmpty
                                ? author.getDisplayName()[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.getDisplayName(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(AppColors.textColor),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (teamName != null)
                          Text(
                            teamName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ExploreLikeButton(
                    entityType: EngagementEntityType.post,
                    entityId: id,
                  ),
                ],
              ),
              if (post.title.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              ],
              if (media != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: media.kind == MediaKind.video
                      ? Container(
                          height: 160,
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(Icons.play_circle_outline, size: 44),
                          ),
                        )
                      : Image.network(
                          media.url,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            color: Colors.black12,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                ),
              ],
              if (match != null || turfName != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (match != null)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(match.versusLabel),
                      ),
                    if (turfName != null)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(turfName),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
