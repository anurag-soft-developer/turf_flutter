import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user/player_stats_models.dart';

class PlayerBadgesSection extends StatelessWidget {
  const PlayerBadgesSection({super.key, required this.badges});

  final List<EarnedBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech,
                size: 20,
                color: const Color(AppColors.accentColor),
              ),
              const SizedBox(width: 8),
              const Text(
                'Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (badges.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 32,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No badges earned yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(AppColors.textSecondaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return _BadgeCard(badge: badge);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final EarnedBadge badge;

  String _formatBadgeName(String badgeId) {
    return badgeId
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(AppColors.accentColor).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppColors.accentColor).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.military_tech,
            size: 24,
            color: const Color(AppColors.accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            _formatBadgeName(badge.badgeId),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
          if (badge.sportType != null)
            Text(
              badge.sportType!,
              style: const TextStyle(
                fontSize: 9,
                color: Color(AppColors.textSecondaryColor),
              ),
            )
          else
            Text(
              DateFormat('MMM yyyy').format(badge.earnedAt),
              style: const TextStyle(
                fontSize: 9,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
