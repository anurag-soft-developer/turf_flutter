import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../rankings/model/player_leaderboard_model.dart';
import '../../team/model/team_leaderboard_model.dart';

class LeaderboardPodiumEntry {
  const LeaderboardPodiumEntry({
    required this.name,
    this.avatarUrl,
    this.id,
  });

  final String name;
  final String? avatarUrl;
  final String? id;

  factory LeaderboardPodiumEntry.fromPlayer(PlayerLeaderboardRow row) {
    return LeaderboardPodiumEntry(
      name: row.name,
      avatarUrl: row.avatar,
      id: row.id,
    );
  }

  factory LeaderboardPodiumEntry.fromTeam(TeamLeaderboardRow row) {
    return LeaderboardPodiumEntry(
      name: row.name,
      avatarUrl: row.avatar,
      id: row.id,
    );
  }
}

typedef LeaderboardPodiumAvatarBuilder = Widget Function(
  LeaderboardPodiumEntry entry,
  double size,
);

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    this.first,
    this.second,
    this.third,
    required this.avatarBuilder,
    this.onSlotTap,
    this.height = 176,
    this.firstAvatarSize = 64,
    this.sideAvatarSize = 52,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 16),
    this.firstPlaceOffset = const Offset(0, -12),
  });

  final LeaderboardPodiumEntry? first;
  final LeaderboardPodiumEntry? second;
  final LeaderboardPodiumEntry? third;
  final LeaderboardPodiumAvatarBuilder avatarBuilder;
  final ValueChanged<LeaderboardPodiumEntry>? onSlotTap;
  final double height;
  final double firstAvatarSize;
  final double sideAvatarSize;
  final EdgeInsets padding;
  final Offset firstPlaceOffset;

  @override
  Widget build(BuildContext context) {
    if (first == null && second == null && third == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumSlot(
                entry: second,
                rank: 2,
                avatarSize: sideAvatarSize,
                avatarBuilder: avatarBuilder,
                onTap: onSlotTap,
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: firstPlaceOffset,
                child: _PodiumSlot(
                  entry: first,
                  rank: 1,
                  avatarSize: firstAvatarSize,
                  avatarBuilder: avatarBuilder,
                  onTap: onSlotTap,
                ),
              ),
            ),
            Expanded(
              child: _PodiumSlot(
                entry: third,
                rank: 3,
                avatarSize: sideAvatarSize,
                avatarBuilder: avatarBuilder,
                onTap: onSlotTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumRankStyle {
  const _PodiumRankStyle({
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final Color badgeColor;
  final Color badgeTextColor;

  static _PodiumRankStyle forRank(int rank) {
    return switch (rank) {
      1 => const _PodiumRankStyle(
          badgeColor: Color(AppColors.primaryColor),
          badgeTextColor: Colors.white,
        ),
      2 => const _PodiumRankStyle(
          badgeColor: Color(AppColors.secondaryColor),
          badgeTextColor: Colors.white,
        ),
      _ => const _PodiumRankStyle(
          badgeColor: Color(AppColors.accentColor),
          badgeTextColor: Colors.white,
        ),
    };
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.avatarSize,
    required this.avatarBuilder,
    this.onTap,
  });

  final LeaderboardPodiumEntry? entry;
  final int rank;
  final double avatarSize;
  final LeaderboardPodiumAvatarBuilder avatarBuilder;
  final ValueChanged<LeaderboardPodiumEntry>? onTap;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const SizedBox.shrink();
    }

    final style = _PodiumRankStyle.forRank(rank);
    final slot = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _RankBadge(rank: rank, style: style),
        const SizedBox(height: 6),
        avatarBuilder(entry!, avatarSize),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry!.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(AppColors.textColor),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) {
      return slot;
    }

    return InkWell(
      onTap: () => onTap!(entry!),
      borderRadius: BorderRadius.circular(12),
      child: slot,
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.style,
  });

  final int rank;
  final _PodiumRankStyle style;

  @override
  Widget build(BuildContext context) {
    final size = rank == 1 ? 28.0 : 24.0;
    return _RankCircle(rank: rank, style: style, size: size);
  }
}

class _RankCircle extends StatelessWidget {
  const _RankCircle({
    required this.rank,
    required this.style,
    required this.size,
  });

  final int rank;
  final _PodiumRankStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.badgeColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: style.badgeTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
