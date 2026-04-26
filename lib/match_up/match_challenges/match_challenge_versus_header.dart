import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../model/team_match_model.dart';

/// How a side should be labeled after a result exists.
enum MatchSideResultLabel {
  /// No finished result (or ongoing / pre-match).
  none,

  /// This team won.
  winner,

  /// Match ended in a draw (show on both teams).
  draw,
}

MatchSideResultLabel resultLabelForTeam(
  TeamMatchModel match,
  String? teamId,
) {
  if (teamId == null || teamId.isEmpty) return MatchSideResultLabel.none;
  if (match.status == TeamMatchStatus.draw) {
    return MatchSideResultLabel.draw;
  }
  if (match.status == TeamMatchStatus.completed) {
    final w = match.winnerTeamHelper.getId();
    if (w != null && w == teamId) return MatchSideResultLabel.winner;
  }
  return MatchSideResultLabel.none;
}

/// Team column: avatar (with optional result badge) + name, tappable to profile.
class MatchChallengeTeamColumn extends StatelessWidget {
  const MatchChallengeTeamColumn({
    super.key,
    required this.teamName,
    this.logoUrl,
    this.teamId,
    this.resultLabel = MatchSideResultLabel.none,
  });

  final String teamName;
  final String? logoUrl;
  final String? teamId;
  final MatchSideResultLabel resultLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: teamId == null || teamId!.isEmpty
          ? null
          : () => Get.toNamed(
                AppConstants.routes.teamProfile,
                arguments: {'teamId': teamId},
              ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarWithResultBadge(
            logoUrl: logoUrl,
            resultLabel: resultLabel,
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithResultBadge extends StatelessWidget {
  const _AvatarWithResultBadge({
    required this.resultLabel,
    this.logoUrl,
  });

  final String? logoUrl;
  final MatchSideResultLabel resultLabel;

  @override
  Widget build(BuildContext context) {
    const double radius = 40;
    return SizedBox(
      width: radius * 2 + 4,
      height: radius * 2 + 4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: const Color(
              AppColors.primaryColor,
            ).withValues(alpha: 0.12),
            backgroundImage: logoUrl != null && logoUrl!.isNotEmpty
                ? NetworkImage(logoUrl!)
                : null,
            child: logoUrl == null || logoUrl!.isEmpty
                ? const Icon(
                    Icons.groups_2_rounded,
                    color: Color(AppColors.primaryColor),
                  )
                : null,
          ),
          if (resultLabel == MatchSideResultLabel.winner)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFFFB300),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 12,
                        color: Color(0xFF5D4200),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Winner',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5D4200),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (resultLabel == MatchSideResultLabel.draw)
            Positioned(
              left: 0,
              right: 0,
              bottom: -4,
              child: Center(
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF5C6BC0),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text(
                      'Draw',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// VS row with optional result styling on avatars.
class MatchChallengeVersusHeader extends StatelessWidget {
  const MatchChallengeVersusHeader({super.key, required this.match});

  final TeamMatchModel match;

  @override
  Widget build(BuildContext context) {
    final fromName = match.fromTeamHelper.getDisplayName();
    final toName = match.toTeamHelper.getDisplayName();
    final fromId = match.fromTeamHelper.getId();
    final toId = match.toTeamHelper.getId();
    final fromLogo = match.fromTeamHelper.getSubsetModel()?.logo;
    final toLogo = match.toTeamHelper.getSubsetModel()?.logo;

    final fromLabel = resultLabelForTeam(match, fromId);
    final toLabel = resultLabelForTeam(match, toId);

    return Row(
      children: [
        Expanded(
          child: MatchChallengeTeamColumn(
            teamName: fromName,
            logoUrl: fromLogo,
            teamId: fromId,
            resultLabel: fromLabel,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(
              AppColors.primaryColor,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              color: Color(AppColors.primaryColor),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: MatchChallengeTeamColumn(
            teamName: toName,
            logoUrl: toLogo,
            teamId: toId,
            resultLabel: toLabel,
          ),
        ),
      ],
    );
  }
}
