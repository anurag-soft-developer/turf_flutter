import 'package:flutter/material.dart';

import '../../../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../../../core/config/constants.dart';
import '../../../../match_up/model/team_match_model.dart';
import '../../../../scoring/cricket/model/cricket_ball_event_model.dart';
import '../cricket_lineup_card.dart';
import 'cricket_scorecard_stats.dart';

class CricketScorecard extends StatefulWidget {
  const CricketScorecard({
    super.key,
    required this.match,
    required this.overs,
    this.parentTabController,
    this.isLoading = false,
    this.onRetry,
  });

  final TeamMatchModel match;
  final List<CricketOverEvent> overs;
  final TabController? parentTabController;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  State<CricketScorecard> createState() => _CricketScorecardState();
}

class _CricketScorecardState extends State<CricketScorecard>
    with SingleTickerProviderStateMixin {
  late final TabController _teamTabController;
  late final String _fromTeamId;
  late final String _toTeamId;
  late final String _fromTeamName;
  late final String _toTeamName;

  @override
  void initState() {
    super.initState();
    _fromTeamId = widget.match.fromTeamHelper.getId() ?? '';
    _toTeamId = widget.match.toTeamHelper.getId() ?? '';
    _fromTeamName = widget.match.fromTeamHelper.getDisplayName();
    _toTeamName = widget.match.toTeamHelper.getDisplayName();
    _teamTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _teamTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.match.cricketState;
    if (cs == null) {
      return _wrapParentSwipe(
        _messageCard(
          'Scorecard will appear once the cricket match has started.',
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(AppColors.dividerColor)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _teamTabController,
            indicatorColor: const Color(AppColors.primaryColor),
            indicatorWeight: 2,
            labelColor: const Color(AppColors.textColor),
            unselectedLabelColor: const Color(AppColors.textSecondaryColor),
            dividerColor: const Color(AppColors.dividerColor),
            tabs: [
              Tab(text: _fromTeamName),
              Tab(text: _toTeamName),
            ],
          ),
          Expanded(
            child: widget.parentTabController == null
                ? TabBarView(
                    controller: _teamTabController,
                    children: _teamScorecardViews(),
                  )
                : ParentLinkedTabBarView(
                    childController: _teamTabController,
                    parentController: widget.parentTabController!,
                    children: _teamScorecardViews(),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _teamScorecardViews() {
    return [
      _TeamScorecardView(
        match: widget.match,
        overs: widget.overs,
        teamId: _fromTeamId,
        isLoading: widget.isLoading,
        onRetry: widget.onRetry,
      ),
      _TeamScorecardView(
        match: widget.match,
        overs: widget.overs,
        teamId: _toTeamId,
        isLoading: widget.isLoading,
        onRetry: widget.onRetry,
      ),
    ];
  }

  Widget _wrapParentSwipe(Widget child) {
    final parent = widget.parentTabController;
    if (parent == null) return child;
    return ParentLinkedHorizontalSwipe(
      parentController: parent,
      child: child,
    );
  }

  Widget _messageCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(AppColors.dividerColor)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(AppColors.textSecondaryColor),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

class _TeamScorecardView extends StatelessWidget {
  const _TeamScorecardView({
    required this.match,
    required this.overs,
    required this.teamId,
    required this.isLoading,
    this.onRetry,
  });

  final TeamMatchModel match;
  final List<CricketOverEvent> overs;
  final String teamId;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && overs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(AppColors.primaryColor),
        ),
      );
    }

    final inningsList = inningsForBattingTeam(match, teamId);
    if (inningsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'This team has not batted yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final innings = inningsList.last;
    final scorecard = buildTeamInningsScorecard(
      match: match,
      overs: overs,
      battingTeamId: teamId,
      innings: innings,
    );

    if (scorecard == null) {
      return const Center(
        child: Text(
          'Scorecard is not available yet.',
          style: TextStyle(
            color: Color(AppColors.textSecondaryColor),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _SectionHeader(
          title: 'Batting',
          columns: const ['R', 'B', '4s', '6s', 'S/R'],
        ),
        ...scorecard.batsmen.map((row) => _BatsmanRow(match: match, row: row)),
        _SummaryRow(
          label: 'Extras',
          value:
              '${scorecard.extras.total} (NB ${scorecard.extras.noBalls}, W ${scorecard.extras.wides}, B ${scorecard.extras.byes + scorecard.extras.legByes})',
        ),
        _SummaryRow(
          label: 'Total runs',
          value:
              '${scorecard.runs} (${scorecard.wickets} wkts, ${scorecard.totalOversLabel} ov)',
        ),
        if (scorecard.yetToBatUserIds.isNotEmpty) ...[
          const _SectionTitle('Yet to bat'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              scorecard.yetToBatUserIds
                  .map((id) => playerDisplayName(match, id))
                  .join(' · '),
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (scorecard.fallOfWickets.isNotEmpty) ...[
          const _SectionTitle('Fall of wickets'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              scorecard.fallOfWickets
                  .map(
                    (fall) =>
                        '${fall.score}/${fall.wicketNumber} (${playerDisplayName(match, fall.batsmanUserId)}, ${_oversFromBalls(fall.legalBalls)} ov)',
                  )
                  .join(' · '),
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
        _SectionHeader(
          title: 'Bowling',
          columns: const ['O', 'M', 'R', 'W', 'Econ'],
        ),
        ...scorecard.bowlers.map((row) => _BowlerRow(match: match, row: row)),
      ],
    );
  }

  String _oversFromBalls(int balls) => '${balls ~/ 6}.${balls % 6}';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.columns});

  final String title;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(AppColors.surfaceColor),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(AppColors.textColor),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          for (final column in columns)
            SizedBox(
              width: 34,
              child: Text(
                column,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(AppColors.dividerColor))),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(AppColors.textColor),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _BatsmanRow extends StatelessWidget {
  const _BatsmanRow({required this.match, required this.row});

  final TeamMatchModel match;
  final CricketBatsmanScorecardRow row;

  @override
  Widget build(BuildContext context) {
    final player = announcedPlayerForUserId(match, row.userId);
    final name = playerDisplayName(match, row.userId);
    final suffix = playerNameSuffix(player);
    final avatar = playerAvatar(match, row.userId);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(AppColors.dividerColor)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(
              AppColors.primaryColor,
            ).withValues(alpha: 0.12),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 16,
                    color: Color(AppColors.textSecondaryColor),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$name$suffix',
                        style: const TextStyle(
                          color: Color(AppColors.textColor),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (row.isOnCrease) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_right,
                        size: 16,
                        color: Color(AppColors.errorColor),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.backgroundColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    row.isOut ? (row.dismissalText ?? 'out') : 'not out',
                    style: const TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StatCell('${row.runs}'),
          _StatCell('${row.balls}'),
          _StatCell('${row.fours}'),
          _StatCell('${row.sixes}'),
          _StatCell(row.strikeRate.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _BowlerRow extends StatelessWidget {
  const _BowlerRow({required this.match, required this.row});

  final TeamMatchModel match;
  final CricketBowlerScorecardRow row;

  @override
  Widget build(BuildContext context) {
    final avatar = playerAvatar(match, row.userId);
    final name = playerDisplayName(match, row.userId);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(AppColors.dividerColor)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(
              AppColors.primaryColor,
            ).withValues(alpha: 0.12),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 16,
                    color: Color(AppColors.textSecondaryColor),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Color(AppColors.textColor),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (row.isCurrentBowler) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_right,
                    size: 16,
                    color: Color(AppColors.errorColor),
                  ),
                ],
              ],
            ),
          ),
          _StatCell(row.oversLabel),
          _StatCell('${row.maidens}'),
          _StatCell('${row.runs}'),
          _StatCell('${row.wickets}'),
          _StatCell(row.economy.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(AppColors.dividerColor)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(AppColors.textColor),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(AppColors.textColor),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
