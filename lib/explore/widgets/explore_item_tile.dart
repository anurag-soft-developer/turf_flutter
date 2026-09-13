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
import '../../match_up/challenge/challenge_controller.dart';
import '../../match_up/challenge/challenge_team_sheet.dart';
import '../../match_up/match_challenges/match_challenge_detail_screen.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/model/team_model.dart';
import '../model/explore_item.dart';
import 'content_post_card.dart';

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
      ExplorePostItem(:final post) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ContentPostCard(post: post),
        ),
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
                  TeamLogo(
                    url: team.logo,
                    size: 48,
                    teamId: team.id,
                  ),
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
                        const SizedBox(height: 3),
                        _ExploreTeamMeta(team: team),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ExploreTeamStatsAndChallenge(team: team),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreTeamMeta extends StatelessWidget {
  const _ExploreTeamMeta({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      color: Color(AppColors.textSecondaryColor),
    );
    final place = team.location?.shortPlaceLabel;

    return Row(
      children: [
        Icon(
          team.sportType.icon,
          size: 13,
          color: const Color(AppColors.textSecondaryColor),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            team.sportType.label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (place != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              '·',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.location_on_outlined,
            size: 13,
            color: Color(AppColors.textSecondaryColor),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              place,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExploreTeamStatsAndChallenge extends StatelessWidget {
  const _ExploreTeamStatsAndChallenge({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ChallengeController>()) {
      return TeamStatsRow.fromTeam(team, compact: true);
    }

    final controller = Get.find<ChallengeController>();
    return Obx(() {
      controller.myMemberships.length;
      controller.challengedOpponentsByFromTeam.length;
      controller.receivedOpponentsByOurTeam.length;
      final isReceived = controller.isReceived(team);
      final isSent = controller.isChallengeSent(team);
      if (!controller.isChallengeableTarget(team)) {
        return TeamStatsRow.fromTeam(team, compact: true);
      }

      return Row(
        children: [
          Expanded(child: TeamStatsRow.fromTeam(team, compact: true)),
          const SizedBox(width: 8),
          ChallengeButton(
            isSent: isSent,
            isReceived: isReceived,
            onTap: isReceived
                ? () => Get.toNamed(
                      AppConstants.routes.matchUpChallenges,
                      arguments: {'tab': 'received'},
                    )
                : isSent
                    ? null
                    : () => onChallengePressed(
                          context: context,
                          controller: controller,
                          opponent: team,
                        ),
          ),
        ],
      );
    });
  }
}
