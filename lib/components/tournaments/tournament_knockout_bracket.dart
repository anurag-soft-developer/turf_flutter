import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tournament_bracket_kit/tournament_bracket_kit.dart';

import '../../core/config/constants.dart';
import '../../core/models/team/team_ref_field_instance.dart';
import '../shared/app_network_image.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/match_challenges/match_challenge_detail_screen.dart';
import '../../match_up/model/team_match_model.dart';
import '../../tournament/detail/tournament_detail_controller.dart';
import '../../tournament/model/tournament_models.dart';
import 'tournament_fixture_teams_sheet.dart';

class TournamentKnockoutBracket extends GetView<TournamentDetailController> {
  const TournamentKnockoutBracket({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fixtures = controller.fixtures
          .where((fixture) => fixture.stage == 'knockout')
          .toList();
      final byId = {for (final fixture in fixtures) fixture.id: fixture};
      final rounds = knockoutBracketRounds(fixtures);

      return RefreshIndicator(
        color: const Color(AppColors.primaryColor),
        onRefresh: controller.load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: TournamentBracket(
                  rounds: rounds,
                  cardWidth: 210,
                  cardHeight: 118,
                  itemsMarginVertical: 16,
                  connectorWidth: 36,
                  lineColor: const Color(AppColors.dividerColor),
                  matchBuilder: (context, match) {
                    final fixture = byId[match.id];
                    final canEdit = fixture != null &&
                        controller.isOrganizer &&
                        fixtureTeamsEditable(fixture);
                    return _BracketFixtureCard(
                      match: match,
                      fixture: fixture,
                      onTap: fixture == null
                          ? null
                          : () => _onFixtureTap(context, fixture),
                      onEdit: canEdit
                          ? () => showTournamentFixtureTeamsSheet(
                                context,
                                fixture: fixture,
                              )
                          : null,
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Future<void> _onFixtureTap(
    BuildContext context,
    TournamentFixtureModel fixture,
  ) async {
    if (!fixtureHasBothTeams(fixture)) {
      AppSnackbar.info(
        title: 'Not ready',
        message: 'This match is still TBD.',
      );
      return;
    }
    await openMatchChallengeDetail(match: fixture.match);
    if (controller.isClosed) return;
    await controller.load();
  }
}

bool fixtureTeamsEditable(TournamentFixtureModel fixture) {
  if (fixture.match.status != TeamMatchStatus.scheduleFinalized) {
    return false;
  }
  return fixture.stage == 'knockout' || fixture.stage == 'league';
}

bool fixtureHasBothTeams(TournamentFixtureModel fixture) {
  return fixture.fromTeamId.isNotEmpty && fixture.toTeamId.isNotEmpty;
}

List<BracketRound> knockoutBracketRounds(List<TournamentFixtureModel> fixtures) {
  final byRound = <int, List<TournamentFixtureModel>>{};
  for (final fixture in fixtures) {
    byRound.putIfAbsent(fixture.round, () => []).add(fixture);
  }
  final roundNumbers = byRound.keys.toList()..sort();
  return [
    for (final round in roundNumbers)
      BracketRound(
        title: knockoutRoundTitle(round, roundNumbers.length),
        matches: [
          for (final fixture in (byRound[round]!
            ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber))))
            BracketMatch(
              id: fixture.id,
              home: _bracketTeam(fixture.match.fromTeamHelper),
              away: _bracketTeam(fixture.match.toTeamHelper),
              isCompleted: _fixtureFinished(fixture),
              score: fixture.decidedWinnerId == null
                  ? null
                  : BracketScore(winnerId: fixture.decidedWinnerId),
            ),
        ],
      ),
  ];
}

String knockoutRoundTitle(int round, int roundCount) {
  final fromFinal = roundCount - round;
  return switch (fromFinal) {
    0 => 'Final',
    1 => 'Semifinals',
    2 => 'Quarterfinals',
    _ => 'Round $round',
  };
}

BracketTeam? _bracketTeam(TeamRefFieldInstance team) {
  final id = team.getId();
  if (id == null || id.isEmpty) return null;
  final logo = team.getSubsetModel()?.logo;
  return BracketTeam(
    id: id,
    name: team.bracketLabel,
    logoUrl: logo == null || logo.isEmpty ? null : logo,
  );
}

bool _fixtureFinished(TournamentFixtureModel fixture) {
  return fixture.match.status == TeamMatchStatus.completed ||
      fixture.match.status == TeamMatchStatus.draw;
}

class _BracketFixtureCard extends StatelessWidget {
  const _BracketFixtureCard({
    required this.match,
    required this.fixture,
    required this.onTap,
    required this.onEdit,
  });

  final BracketMatch match;
  final TournamentFixtureModel? fixture;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final winnerId = fixture?.decidedWinnerId;
    final status = fixture?.match.status;
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 8),
          child: Column(
            children: [
              Row(
                children: [
                  _StatusChip(status: status),
                  const Spacer(),
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit teams',
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: Color(AppColors.primaryColor),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _TeamSide(
                        team: match.home,
                        winner:
                            winnerId != null && winnerId == match.home?.id,
                      ),
                    ),
                    const _VsMark(),
                    Expanded(
                      child: _TeamSide(
                        team: match.away,
                        winner:
                            winnerId != null && winnerId == match.away?.id,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.team, required this.winner});

  final BracketTeam? team;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final missing = team == null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TeamAvatar(team: team, winner: winner),
        const SizedBox(height: 4),
        Text(
          missing ? 'TBD' : team!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontStyle: missing ? FontStyle.italic : FontStyle.normal,
            height: 1.1,
            color: missing
                ? const Color(AppColors.textSecondaryColor)
                : const Color(AppColors.textColor),
          ),
        ),
      ],
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.team, required this.winner});

  final BracketTeam? team;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final logo = team?.logoUrl;
    final hasLogo = logo != null && logo.isNotEmpty;
    final initial = _initial(team?.name);
    return SizedBox(
      width: 36,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(AppColors.dividerColor).withValues(alpha: 0.8),
              ),
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(AppColors.primaryColor).withValues(
                alpha: 0.1,
              ),
              backgroundImage: hasLogo ? AppNetworkImage.provider(logo) : null,
              child: hasLogo
                  ? null
                  : team == null
                      ? const Icon(
                          AppIcons.teamPlaceholder,
                          size: 16,
                          color: Color(AppColors.textSecondaryColor),
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.primaryColor),
                          ),
                        ),
            ),
          ),
          if (winner)
            const Positioned(
              right: -2,
              bottom: -1,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 14,
                color: Color(0xFFFFB300),
              ),
            ),
        ],
      ),
    );
  }

  String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _VsMark extends StatelessWidget {
  const _VsMark();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        'VS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: const Color(AppColors.textSecondaryColor).withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TeamMatchStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

(String, Color) _statusStyle(TeamMatchStatus? status) {
  return switch (status) {
    TeamMatchStatus.ongoing => ('Live', const Color(0xFF2E7D32)),
    TeamMatchStatus.completed => ('Completed', const Color(AppColors.primaryColor)),
    TeamMatchStatus.draw => ('Draw', const Color(0xFF6D4C41)),
    TeamMatchStatus.cancelled => ('Cancelled', const Color(0xFFC62828)),
    TeamMatchStatus.abandoned => ('Abandoned', const Color(0xFFC62828)),
    _ => ('Upcoming', const Color(AppColors.textSecondaryColor)),
  };
}
