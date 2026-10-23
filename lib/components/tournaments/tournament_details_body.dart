import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/rankings/leaderboard_podium.dart';
import '../../core/config/constants.dart';
import '../../core/utils/date_util.dart';
import '../../team/model/team_model.dart';
import '../../tournament/detail/tournament_detail_controller.dart';
import '../../tournament/model/tournament_models.dart';
import '../../tournament/tournament_podium.dart';
import 'tournament_organizers_section.dart';

class TournamentDetailsBody extends StatelessWidget {
  const TournamentDetailsBody({
    super.key,
    required this.tournament,
    required this.controller,
  });

  final TournamentModel tournament;
  final TournamentDetailController controller;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final primary = const Color(AppColors.primaryColor);

    final podium = tournamentPodium(
      tournament: tournament,
      fixtures: controller.fixtures,
      table: controller.table.value,
      entries: controller.entries,
    );

    return RefreshIndicator(
      color: primary,
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (tournament.coverImages.isNotEmpty)
            SizedBox(
              height: 160,
              child: PageView.builder(
                itemCount: tournament.coverImages.length,
                itemBuilder: (context, index) {
                  final url = tournament.coverImages[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: primary.withValues(alpha: 0.08),
                        child: const Icon(Icons.image_outlined, size: 48),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (tournament.coverImages.isNotEmpty) const SizedBox(height: 16),
          if (podium != null)
            _Section(
              children: [
                const Text(
                  'Champions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                _ChampionsPodium(podium: podium),
              ],
            ),
          _Section(
            children: [
              _Row('Format', tournament.format),
              _Row('Status', tournament.status),
              _Row('Sport', _sportLabel(tournament.sportType)),
              if (tournament.category != null)
                _Row('Category', tournament.category!),
              if (tournament.pitchType != null)
                _Row('Pitch type', tournament.pitchType!),
              if (tournament.sportType == 'cricket' &&
                  tournament.ballType != null)
                _Row('Ball type', tournament.ballType!),
              if (tournament.sportType == 'football' &&
                  tournament.matchType != null)
                _Row('Match type', tournament.matchType!),
              if (tournament.sportType == 'football' &&
                  tournament.durationMinutes != null)
                _Row('Duration', '${tournament.durationMinutes} minutes'),
              if (tournament.sportType != 'football')
                _Row('Overs / innings', '${tournament.maxOvers}'),
              _Row(
                'Teams',
                controller.isOrganizer
                    ? (tournament.maxTeams != null
                          ? '${controller.acceptedCount} / ${tournament.maxTeams} accepted'
                          : '${controller.acceptedCount} joined (open roster)')
                    : '${controller.acceptedCount} teams',
              ),
              if (controller.isOrganizer && tournament.rosterLockedAt != null)
                _Row('Roster', 'Locked'),
              if (controller.isOrganizer)
                _Row(
                  'Visibility',
                  tournament.isPublic ? 'Public' : 'Invite only',
                ),
            ],
          ),
          if (tournament.venueName != null && tournament.venueName!.isNotEmpty)
            _Section(children: [_Row('Location', tournament.venueName!)]),
          _Section(
            children: [
              if (tournament.startDate != null)
                _Row(
                  'Start',
                  formatDateOnly(tournament.startDate!.toLocal(), locale),
                ),
              if (tournament.endDate != null)
                _Row(
                  'End',
                  formatDateOnly(tournament.endDate!.toLocal(), locale),
                ),
              if (tournament.registrationDeadline != null)
                _Row(
                  'Registration closes',
                  formatDateOnly(
                    tournament.registrationDeadline!.toLocal(),
                    locale,
                  ),
                ),
            ],
          ),
          if (tournament.description != null &&
              tournament.description!.isNotEmpty)
            _Section(
              children: [
                Text(
                  tournament.description!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          if (tournament.organizerList.isNotEmpty)
            _Section(
              children: [TournamentOrganizersSection(tournament: tournament)],
            ),
        ],
      ),
    );
  }
}

class _ChampionsPodium extends StatelessWidget {
  const _ChampionsPodium({required this.podium});

  final TournamentPodium podium;

  @override
  Widget build(BuildContext context) {
    LeaderboardPodiumEntry? slot(TournamentPodiumTeam? team) {
      if (team == null) return null;
      return LeaderboardPodiumEntry(
        name: team.name,
        avatarUrl: team.logo,
        id: team.id,
      );
    }

    return LeaderboardPodium(
      first: slot(podium.first),
      second: slot(podium.second),
      third: slot(podium.third),
      padding: const EdgeInsets.only(top: 8),
      avatarBuilder: (entry, size) => TeamLogo(
        url: entry.avatarUrl ?? '',
        size: size,
        teamId: entry.id ?? '',
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _sportLabel(String raw) {
  final key = raw.trim().toLowerCase();
  for (final sport in TeamSportType.values) {
    if (sport.name == key) return sport.label;
  }
  return raw;
}
