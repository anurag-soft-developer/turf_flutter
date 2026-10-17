import 'package:flutter/material.dart';

import '../shared/app_network_image.dart';
import '../../core/config/constants.dart';
import '../../core/utils/date_util.dart';
import '../../team/model/team_model.dart';
import '../../tournament/model/tournament_models.dart';

class TournamentListCard extends StatelessWidget {
  const TournamentListCard({
    super.key,
    required this.tournament,
    required this.onTap,
    this.footer,
  });

  final TournamentModel tournament;
  final VoidCallback onTap;
  final Widget? footer;

  static const _coverWidth = 108.0;
  static const _cardHeight = 132.0;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final primary = const Color(AppColors.primaryColor);
    final coverUrl = tournament.coverImages
        .where((url) => url.trim().isNotEmpty)
        .firstOrNull;
    final sport = _sportType(tournament.sportType);
    final status = _statusPresentation(tournament.status);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _cardHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _coverWidth,
                    child: _TournamentCoverThumb(
                      imageUrl: coverUrl,
                      sport: sport,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _StatusChip(
                                label: status.label,
                                color: status.color,
                              ),
                              if (sport != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  sport.icon,
                                  size: 16,
                                  color: primary.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sport.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primary.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tournament.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatLine(tournament),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                          if (tournament.startDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              formatDateOnly(
                                tournament.startDate!.toLocal(),
                                locale,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }

  static TeamSportType? _sportType(String raw) {
    final key = raw.trim().toLowerCase();
    for (final sport in TeamSportType.values) {
      if (sport.name == key) return sport;
    }
    return null;
  }

  static String _formatLine(TournamentModel t) {
    final format = _humanFormat(t.format);
    final teams = t.maxTeams != null ? '${t.maxTeams} teams' : 'Open roster';
    final overs = '${t.maxOvers} overs';
    final venue = t.venueName?.trim();
    final parts = [format, teams, overs];
    if (venue != null && venue.isNotEmpty) parts.add(venue);
    return parts.join(' · ');
  }

  static String _humanFormat(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'round_robin' => 'Round robin',
      'knockout' => 'Knockout',
      'hybrid' => 'League + knockout',
      _ => raw.replaceAll('_', ' '),
    };
  }

  static _StatusStyle _statusPresentation(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'ongoing' => _StatusStyle('Live', const Color(0xFFEF4444)),
      'scheduled' => _StatusStyle(
        'Scheduled',
        const Color(AppColors.primaryColor),
      ),
      'inviting' => _StatusStyle('Registration', const Color(0xFF3B82F6)),
      'draft' => _StatusStyle(
        'Draft',
        const Color(AppColors.textSecondaryColor),
      ),
      'completed' => _StatusStyle('Completed', const Color(0xFF10B981)),
      'cancelled' => _StatusStyle(
        'Cancelled',
        const Color(AppColors.textSecondaryColor),
      ),
      _ => _StatusStyle(
        raw.isEmpty ? 'Unknown' : raw[0].toUpperCase() + raw.substring(1),
        const Color(AppColors.textSecondaryColor),
      ),
    };
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.color);

  final String label;
  final Color color;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _TournamentCoverThumb extends StatelessWidget {
  const _TournamentCoverThumb({required this.imageUrl, this.sport});

  final String? imageUrl;
  final TeamSportType? sport;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(AppColors.primaryColor);
    return SizedBox.expand(
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? AppNetworkImage(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(primary, sport),
            )
          : _placeholder(primary, sport),
    );
  }

  Widget _placeholder(Color primary, TeamSportType? sport) {
    return ColoredBox(
      color: primary.withValues(alpha: 0.06),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.18),
              primary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            sport?.icon ?? Icons.emoji_events_outlined,
            size: 40,
            color: primary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
