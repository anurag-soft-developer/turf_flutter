import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/match_history/match_card.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../components/tournaments/tournament_details_body.dart';
import '../../components/tournaments/tournament_entry_tile.dart';
import '../../components/tournaments/tournament_fixture_teams_sheet.dart';
import '../../components/tournaments/tournament_knockout_bracket.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/match_challenges/match_challenge_detail_screen.dart';
import '../../match_up/model/team_match_model.dart';
import '../model/tournament_models.dart';
import '../tournament_team_count.dart';
import 'tournament_detail_controller.dart';

enum _TournamentMenuAction {
  edit,
  manageTeams,
  manageOrganizers,
  lockRoster,
  generateDraw,
  requestToJoin,
  cancelTournament,
  deleteTournament,
}

class TournamentDetailScreen extends HookWidget {
  const TournamentDetailScreen({super.key});

  static const _tabItems = [
    AppTabItem(label: 'Details'),
    AppTabItem(label: 'Teams'),
    AppTabItem(label: 'Fixtures'),
    AppTabItem(label: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TournamentDetailController>();
    final ticker = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: _tabItems.length, vsync: ticker),
      [ticker],
    );

    useEffect(() {
      return () => tabController.dispose();
    }, [tabController]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(
        title: Obx(
          () => Text(controller.tournament.value?.name ?? 'Tournament'),
        ),
        actions: [
          Obx(() => _buildAppBarMenu(context, controller)),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.tournament.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final tournament = controller.tournament.value;
        if (tournament == null) {
          return const Center(child: Text('Tournament not found.'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSegmentedTabs(
              controller: tabController,
              items: _tabItems,
              fillWidth: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            ),
            Expanded(
              child: AppSegmentedTabView(
                controller: tabController,
                children: [
                  Obx(
                    () => TournamentDetailsBody(
                      tournament: controller.tournament.value ?? tournament,
                      controller: controller,
                    ),
                  ),
                  const _TeamsTab(),
                  const _FixturesTab(),
                  const _TableTab(),
                ],
              ),
            ),
            if (controller.isOrganizer &&
                tournament.status == 'inviting' &&
                !controller.isRosterLocked)
              _RosterActionsBar(
                onInvites: () async {
                  await Get.toNamed(
                    AppConstants.routes.tournamentTeamEntries(tournament.id),
                  );
                  await controller.load();
                },
                onLockRoster: () => _onLockRoster(context, controller, tournament),
              )
            else if (controller.isOrganizer &&
                tournament.status == 'inviting' &&
                controller.isRosterLocked)
              _GenerateFixtureBar(
                onPressed: () => _onGenerateFixture(context, controller, tournament),
              ),
          ],
        );
      }),
    );
  }
}

Widget _buildAppBarMenu(
  BuildContext context,
  TournamentDetailController controller,
) {
  final tournament = controller.tournament.value;
  if (tournament == null) {
    return const SizedBox.shrink();
  }

  // Read reactive fields inside Obx (not in a separate widget build).
  final menuEntries = _menuEntries(controller, tournament);
  if (menuEntries.isEmpty) {
    return const SizedBox.shrink();
  }

  return PopupMenuButton<_TournamentMenuAction>(
    tooltip: 'Tournament actions',
    icon: const Icon(Icons.more_vert),
    onSelected: (action) =>
        _onMenuSelected(context, controller, tournament, action),
    itemBuilder: (context) => [
      for (final entry in menuEntries)
        PopupMenuItem<_TournamentMenuAction>(
          value: entry.action,
          enabled: entry.enabled,
          child: Text(entry.label),
        ),
    ],
  );
}

class _MenuEntry {
  const _MenuEntry({
    required this.action,
    required this.label,
    this.enabled = true,
  });

  final _TournamentMenuAction action;
  final String label;
  final bool enabled;
}

List<_MenuEntry> _menuEntries(
  TournamentDetailController controller,
  TournamentModel tournament,
) {
  final entries = <_MenuEntry>[];
  final status = tournament.status;

  if (controller.isOrganizer) {
    entries.add(
      const _MenuEntry(
        action: _TournamentMenuAction.manageOrganizers,
        label: 'Organizers',
      ),
    );
  }

  if (controller.isOrganizer &&
      (status == 'draft' || status == 'inviting')) {
    entries.add(
      const _MenuEntry(
        action: _TournamentMenuAction.edit,
        label: 'Edit details',
      ),
    );
  }

  if (controller.isOrganizer && status == 'inviting') {
    entries.add(
      const _MenuEntry(
        action: _TournamentMenuAction.manageTeams,
        label: 'Teams & invites',
      ),
    );
    if (!controller.isRosterLocked) {
      entries.add(
        const _MenuEntry(
          action: _TournamentMenuAction.lockRoster,
          label: 'Lock lineup',
        ),
      );
    } else {
      entries.add(
        _MenuEntry(
          action: _TournamentMenuAction.generateDraw,
          label: 'Generate fixture',
          enabled:
              tournament.maxTeams != null &&
              controller.acceptedCount == tournament.maxTeams,
        ),
      );
    }
  }

  if (!controller.isOrganizer && status == 'inviting' && !controller.isRosterLocked) {
    entries.add(
      _MenuEntry(
        action: _TournamentMenuAction.requestToJoin,
        label: 'Request to join',
        enabled: controller.eligibleActingTeams.isNotEmpty,
      ),
    );
  }

  if (controller.isOrganizer &&
      status != 'completed' &&
      status != 'cancelled') {
    entries.add(
      const _MenuEntry(
        action: _TournamentMenuAction.cancelTournament,
        label: 'Cancel tournament',
      ),
    );
  }

  if (controller.canDelete) {
    entries.add(
      const _MenuEntry(
        action: _TournamentMenuAction.deleteTournament,
        label: 'Delete tournament',
      ),
    );
  }

  return entries;
}

Future<void> _onMenuSelected(
  BuildContext context,
  TournamentDetailController controller,
  TournamentModel tournament,
  _TournamentMenuAction action,
) async {
  switch (action) {
    case _TournamentMenuAction.edit:
      final refreshed = await Get.toNamed(
        AppConstants.routes.editTournament(tournament.id),
      );
      if (refreshed == true) await controller.load();
      return;
    case _TournamentMenuAction.manageTeams:
      await Get.toNamed(AppConstants.routes.tournamentTeamEntries(tournament.id));
      await controller.load();
      return;
    case _TournamentMenuAction.manageOrganizers:
      await Get.toNamed(AppConstants.routes.tournamentOrganizers(tournament.id));
      await controller.load();
      return;
    case _TournamentMenuAction.lockRoster:
      await _onLockRoster(context, controller, tournament);
      return;
    case _TournamentMenuAction.generateDraw:
      await _onGenerateFixture(context, controller, tournament);
      return;
    case _TournamentMenuAction.requestToJoin:
      await _request(context, controller);
      return;
    case _TournamentMenuAction.cancelTournament:
      await _confirm(
        context,
        'Cancel this tournament?',
        'Unplayed fixtures will be cancelled.',
        controller.cancel,
      );
      return;
    case _TournamentMenuAction.deleteTournament:
      await _confirmDelete(context, controller);
      return;
  }
}

Future<void> _confirmRemoveAccepted(
  BuildContext context,
  TournamentEntryModel entry,
) async {
  final controller = Get.find<TournamentDetailController>();
  await _confirm(
    context,
    'Remove ${entry.teamName}?',
    'They can be invited again before you lock the lineup.',
    () => controller.removeAcceptedTeam(entry.id),
  );
}

Future<void> _confirmWithdrawRequest(
  BuildContext context,
  TournamentEntryModel entry,
) async {
  final controller = Get.find<TournamentDetailController>();
  await _confirm(
    context,
    'Withdraw request?',
    'Remove your join request from this tournament.',
    () => controller.withdrawRequest(entry.id),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  TournamentDetailController controller,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this tournament?'),
      content: const Text(
        'This removes the tournament, teams, and invites permanently. '
        'Only possible before the tournament has started.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final deleted = await controller.deleteTournament();
  if (!deleted) return;
  AppSnackbar.success(
    title: 'Deleted',
    message: 'The tournament was removed.',
  );
  await Get.offNamed(AppConstants.routes.tournaments);
  if (Get.isRegistered<QueryClient>()) {
    await Get.find<QueryClient>().invalidateQueries(
      queryKey: QueryKeys.tournamentsMinePrefix,
    );
  }
}

Future<void> _onLockRoster(
  BuildContext context,
  TournamentDetailController controller,
  TournamentModel tournament,
) async {
  final reason = validateTournamentTeamCount(
    tournament.format,
    controller.acceptedCount,
  );
  if (reason != null) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_formatName(tournament.format)} format'),
        content: tournament.format == 'knockout'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.acceptedCount < tournamentMinKnockoutTeams
                        ? inviteAtLeastTeamsMessage(tournament.format)
                        : 'Select 4, 8, 16, 32, or 64 teams.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Change the format to start with any number of teams.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              )
            : Text(
                '$reason\n\n${formatHelpTextForCreate(tournament.format)}',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return;
  }
  await _confirm(
    context,
    'Lock the lineup?',
    'Registration closes. Remove any extra teams first — '
        'the locked count is ${controller.acceptedCount} teams.',
    controller.lockRoster,
  );
}

Future<void> _onGenerateFixture(
  BuildContext context,
  TournamentDetailController controller,
  TournamentModel tournament,
) async {
  if (tournament.maxTeams == null ||
      controller.acceptedCount != tournament.maxTeams) {
    return;
  }
  await _confirm(
    context,
    'Generate the fixture?',
    'Fixtures will be created for ${tournament.maxTeams} teams.',
    controller.generateDraw,
  );
}

String _formatName(String format) {
  return switch (format) {
    'league' => 'League',
    'hybrid' => 'Hybrid',
    _ => 'Knockout',
  };
}

Future<void> _confirm(
  BuildContext context,
  String title,
  String message,
  Future<bool> Function() action,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await action();
  }
}

Future<void> _request(
  BuildContext context,
  TournamentDetailController controller,
) async {
  final teamId = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Request with'),
      children: [
        for (final team in controller.eligibleActingTeams)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, team.id),
            child: Text(team.name),
          ),
      ],
    ),
  );
  if (teamId == null) return;
  final ok = await controller.requestToJoin(teamId);
  if (ok) {
    AppSnackbar.success(
      title: 'Requested',
      message: 'The organizer can accept your team.',
    );
  }
}

class _PullToRefreshMessage extends StatelessWidget {
  const _PullToRefreshMessage({
    required this.message,
    required this.onRefresh,
  });

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(AppColors.primaryColor),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: Center(
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterActionsBar extends StatelessWidget {
  const _RosterActionsBar({
    required this.onInvites,
    required this.onLockRoster,
  });

  final VoidCallback onInvites;
  final VoidCallback onLockRoster;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Material(
                    color: const Color(AppColors.backgroundColor),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onInvites,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              size: 18,
                              color: Color(AppColors.primaryColor),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Invites',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.primaryColor),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onLockRoster,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Lock lineup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateFixtureBar extends StatelessWidget {
  const _GenerateFixtureBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Generate fixture'),
          ),
        ),
      ),
    );
  }
}

class _TeamsTab extends GetView<TournamentDetailController> {
  const _TeamsTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.entries
          .where((entry) => entry.status == 'accepted')
          .toList();
      if (items.isEmpty) {
        return _PullToRefreshMessage(
          message: controller.isOrganizer
              ? 'No accepted teams yet.'
              : 'No teams in the roster yet.',
          onRefresh: controller.load,
        );
      }
      final totalLabel = items.length == 1 ? '1 team' : '${items.length} teams';
      return RefreshIndicator(
        color: const Color(AppColors.primaryColor),
        onRefresh: controller.load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textColor),
                ),
              );
            }
            final entry = items[index - 1];
            return TournamentEntryTile(
              entry: entry,
              showStatusAndDirection: false,
              onRemoveAccepted: (e) => _confirmRemoveAccepted(context, e),
              onWithdrawRequest: (e) => _confirmWithdrawRequest(context, e),
            );
          },
        ),
      );
    });
  }
}

enum _FixtureView { cards, bracket }

class _FixturesTab extends StatefulWidget {
  const _FixturesTab();

  @override
  State<_FixturesTab> createState() => _FixturesTabState();
}

class _FixturesTabState extends State<_FixturesTab> {
  _FixtureView? _view;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TournamentDetailController>();
    return Obx(() {
      final format = controller.tournament.value?.format;
      final items = controller.fixtures.toList();
      if (items.isEmpty) {
        return _PullToRefreshMessage(
          message: 'Fixtures appear after the draw.',
          onRefresh: controller.load,
        );
      }

      final canBracket = format == 'knockout' || format == 'hybrid';
      final view = canBracket
          ? (_view ??
              (format == 'knockout'
                  ? _FixtureView.bracket
                  : _FixtureView.cards))
          : _FixtureView.cards;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canBracket)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: Alignment.center,
                child: SegmentedButton<_FixtureView>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _FixtureView.cards,
                      icon: Icon(Icons.view_list_rounded, size: 18),
                      label: Text('Cards'),
                      tooltip: 'Match cards',
                    ),
                    ButtonSegment(
                      value: _FixtureView.bracket,
                      icon: Icon(Icons.account_tree_outlined, size: 18),
                      label: Text('Bracket'),
                      tooltip: 'Knockout bracket',
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (next) {
                    setState(() => _view = next.first);
                  },
                ),
              ),
            ),
          Expanded(
            child: view == _FixtureView.bracket
                ? _bracketPane(controller)
                : _FixtureCardList(fixtures: items),
          ),
        ],
      );
    });
  }

  Widget _bracketPane(TournamentDetailController controller) {
    final hasKnockout = controller.fixtures.any(
      (fixture) => fixture.stage == 'knockout',
    );
    if (!hasKnockout) {
      return _PullToRefreshMessage(
        message: 'Knockout bracket appears after the league stage.',
        onRefresh: controller.load,
      );
    }
    return const TournamentKnockoutBracket();
  }
}

class _FixtureCardList extends GetView<TournamentDetailController> {
  const _FixtureCardList({required this.fixtures});

  final List<TournamentFixtureModel> fixtures;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(AppColors.primaryColor),
      onRefresh: controller.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: fixtures.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final fixture = fixtures[index];
          final match = fixture.match;
          final canEdit =
              controller.isOrganizer && fixtureTeamsEditable(fixture);
          return MatchCard(
            match: match,
            isHistory: _isFixtureHistory(match),
            onEdit: canEdit
                ? () => showTournamentFixtureTeamsSheet(
                      context,
                      fixture: fixture,
                    )
                : null,
            onTap: () async {
              await openMatchChallengeDetail(match: match);
              if (controller.isClosed) return;
              await controller.load();
            },
            footer: _FixtureCardFooter(label: fixture.label),
          );
        },
      ),
    );
  }
}

class _TableTab extends GetView<TournamentDetailController> {
  const _TableTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final table = controller.table.value;
      if (table == null || table.standings.isEmpty) {
        return _PullToRefreshMessage(
          message: 'The table appears after the draw.',
          onRefresh: controller.load,
        );
      }
      return RefreshIndicator(
        color: const Color(AppColors.primaryColor),
        onRefresh: controller.load,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (final group in table.standings) ...[
            _StandingsGroupTable(
              title: _standingsTitle(group.groupLabel),
              rows: group.rows,
              football: controller.tournament.value?.sportType == 'football',
            ),
            const SizedBox(height: 16),
          ],
          for (final pending in table.pendingQualifiers)
            if (controller.isOrganizer)
              _QualifierPick(pending: pending, rows: _rowsFor(table, pending)),
        ],
        ),
      );
    });
  }

  String _standingsTitle(String? groupLabel) {
    if (groupLabel != null) return 'Group $groupLabel';
    final format = controller.tournament.value?.format;
    if (format == 'knockout') return 'Standings';
    return 'League';
  }

  List<StandingRowModel> _rowsFor(
    TournamentTableModel table,
    PendingQualifierModel pending,
  ) {
    final group = table.standings
        .where(
          (item) => (item.groupLabel ?? '') == pending.groupLabel,
        )
        .firstOrNull;
    return group?.rows ?? const [];
  }
}

class _StandingsGroupTable extends StatelessWidget {
  const _StandingsGroupTable({
    required this.title,
    required this.rows,
    required this.football,
  });

  final String title;
  final List<StandingRowModel> rows;
  final bool football;

  static const _cricketColumns = [
    _StandingsColumn('P', 'Played'),
    _StandingsColumn('W', 'Won'),
    _StandingsColumn('D', 'Drawn'),
    _StandingsColumn('L', 'Lost'),
    _StandingsColumn('NRR', 'Net run rate'),
    _StandingsColumn('Pts', 'Points'),
  ];

  static const _footballColumns = [
    _StandingsColumn('P', 'Played'),
    _StandingsColumn('W', 'Won'),
    _StandingsColumn('D', 'Drawn'),
    _StandingsColumn('L', 'Lost'),
    _StandingsColumn('GD', 'Goal difference'),
    _StandingsColumn('Pts', 'Points'),
  ];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final columns = football ? _footballColumns : _cricketColumns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(AppColors.dividerColor).withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(2.4),
                      1: FixedColumnWidth(36),
                      2: FixedColumnWidth(36),
                      3: FixedColumnWidth(36),
                      4: FixedColumnWidth(36),
                      5: FixedColumnWidth(52),
                      6: FixedColumnWidth(40),
                    },
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: const Color(AppColors.dividerColor)
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: const Color(AppColors.primaryColor)
                              .withValues(alpha: 0.06),
                        ),
                        children: [
                          _StandingsHeaderCell('Team', align: TextAlign.start),
                          for (final col in columns)
                            _StandingsHeaderCell(col.short, tooltip: col.long),
                        ],
                      ),
                      for (var i = 0; i < rows.length; i++)
                        TableRow(
                          decoration: i.isOdd
                              ? BoxDecoration(
                                  color: const Color(AppColors.backgroundColor)
                                      .withValues(alpha: 0.55),
                                )
                              : null,
                          children: [
                            _StandingsTeamCell(name: rows[i].teamName),
                            _StandingsStatCell('${rows[i].played}'),
                            _StandingsStatCell('${rows[i].won}'),
                            _StandingsStatCell('${rows[i].drawn}'),
                            _StandingsStatCell('${rows[i].lost}'),
                            _StandingsStatCell(
                              football
                                  ? _goalDifferenceLabel(rows[i].goalDifference)
                                  : rows[i].nrr.toStringAsFixed(3),
                              monospace: true,
                            ),
                            _StandingsStatCell(
                              '${rows[i].points}',
                              emphasized: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _goalDifferenceLabel(int difference) {
  if (difference > 0) return '+$difference';
  return '$difference';
}

class _StandingsColumn {
  const _StandingsColumn(this.short, this.long);

  final String short;
  final String long;
}

class _StandingsHeaderCell extends StatelessWidget {
  const _StandingsHeaderCell(
    this.label, {
    this.align = TextAlign.center,
    this.tooltip,
  });

  final String label;
  final TextAlign align;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: align,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Color(AppColors.textSecondaryColor),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: tooltip == null
          ? text
          : Tooltip(message: tooltip!, child: text),
    );
  }
}

class _StandingsTeamCell extends StatelessWidget {
  const _StandingsTeamCell({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(AppColors.textColor),
        ),
      ),
    );
  }
}

class _StandingsStatCell extends StatelessWidget {
  const _StandingsStatCell(
    this.value, {
    this.emphasized = false,
    this.monospace = false,
  });

  final String value;
  final bool emphasized;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: emphasized ? 14 : 13,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          fontFeatures: monospace ? const [FontFeature.tabularFigures()] : null,
          color: emphasized
              ? const Color(AppColors.primaryColor)
              : const Color(AppColors.textColor),
        ),
      ),
    );
  }
}

bool _isFixtureHistory(TeamMatchModel match) {
  return switch (match.status) {
    TeamMatchStatus.completed ||
    TeamMatchStatus.draw ||
    TeamMatchStatus.rejected ||
    TeamMatchStatus.cancelled ||
    TeamMatchStatus.abandoned ||
    TeamMatchStatus.expired => true,
    _ => false,
  };
}

class _FixtureCardFooter extends StatelessWidget {
  const _FixtureCardFooter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(AppColors.textSecondaryColor),
      ),
    );
  }
}

class _QualifierPick extends StatefulWidget {
  const _QualifierPick({required this.pending, required this.rows});

  final PendingQualifierModel pending;
  final List<StandingRowModel> rows;

  @override
  State<_QualifierPick> createState() => _QualifierPickState();
}

class _QualifierPickState extends State<_QualifierPick> {
  late final Set<String> _selected = {...widget.pending.lockedTeamIds};

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TournamentDetailController>();
    final choices = widget.rows.where(
      (row) =>
          widget.pending.lockedTeamIds.contains(row.teamId) ||
          widget.pending.tiedTeamIds.contains(row.teamId),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pending.groupLabel.isEmpty
                  ? 'The league table is tied on the cutoff. Pick ${widget.pending.advanceCount} teams for the knockout.'
                  : 'Group ${widget.pending.groupLabel} is tied. Pick ${widget.pending.advanceCount} teams to advance.',
            ),
            for (final row in choices)
              CheckboxListTile(
                value: _selected.contains(row.teamId),
                title: Text(row.teamName),
                onChanged: widget.pending.lockedTeamIds.contains(row.teamId)
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(row.teamId);
                          } else {
                            _selected.remove(row.teamId);
                          }
                        });
                      },
              ),
            FilledButton(
              onPressed: _selected.length == widget.pending.advanceCount
                  ? () => controller.pickQualifiers(
                        widget.pending.groupLabel,
                        _selected.toList(),
                      )
                  : null,
              child: const Text('Advance these teams'),
            ),
          ],
        ),
      ),
    );
  }
}
