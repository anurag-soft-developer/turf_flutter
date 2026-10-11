import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/team/team_ref_field_instance.dart';
import '../../match_up/model/team_match_model.dart';
import '../../tournament/detail/tournament_detail_controller.dart';
import '../../tournament/model/tournament_models.dart';
import '../match_up/match_pick_versus_row.dart';
import '../match_up/team_logo.dart';

Future<void> showTournamentFixtureTeamsSheet(
  BuildContext context, {
  required TournamentFixtureModel fixture,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _FixtureTeamsSheet(fixture: fixture),
        ),
      );
    },
  );
}

class _TeamChoice {
  const _TeamChoice({
    required this.id,
    required this.name,
    this.logo = '',
  });

  final String id;
  final String name;
  final String logo;
}

class _FixtureTeamsSheet extends StatefulWidget {
  const _FixtureTeamsSheet({required this.fixture});

  final TournamentFixtureModel fixture;

  @override
  State<_FixtureTeamsSheet> createState() => _FixtureTeamsSheetState();
}

class _FixtureTeamsSheetState extends State<_FixtureTeamsSheet> {
  late String? _homeId = _emptyToNull(widget.fixture.fromTeamId);
  late String? _awayId = _emptyToNull(widget.fixture.toTeamId);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TournamentDetailController>();
    final choices = _choices(controller);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Match ${widget.fixture.matchNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.fixture.stage == 'league'
                  ? 'Pick the teams for this match.'
                  : 'Pick the teams for this match. Later matches that depend on it are cleared.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 24),
            MatchPickVersusRow(
              left: _versusSide(
                id: _homeId,
                caption: 'Home',
                choices: choices,
                onTap: _saving
                    ? null
                    : () => _pickSide(
                          title: 'Select home team',
                          selected: _homeId,
                          other: _awayId,
                          choices: choices,
                          controller: controller,
                          onPicked: (id) => setState(() => _homeId = id),
                        ),
              ),
              right: _versusSide(
                id: _awayId,
                caption: 'Away',
                choices: choices,
                onTap: _saving
                    ? null
                    : () => _pickSide(
                          title: 'Select away team',
                          selected: _awayId,
                          other: _homeId,
                          choices: choices,
                          controller: controller,
                          onPicked: (id) => setState(() => _awayId = id),
                        ),
              ),
            ),
            if (_pairAlreadyScheduled(controller)) ...[
              const SizedBox(height: 12),
              const Text(
                'This pair is already scheduled.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        final home = _homeId;
                        _homeId = _awayId;
                        _awayId = home;
                      }),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Swap sides'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : () => _save(controller),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_saving ? 'Saving…' : 'Save pair'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(TournamentDetailController controller) async {
    setState(() => _saving = true);
    final ok = await controller.updateFixtureTeams(
      widget.fixture.id,
      fromTeamId: _homeId,
      toTeamId: _awayId,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = false);
  }

  MatchPickVersusTeam _versusSide({
    required String? id,
    required String caption,
    required List<_TeamChoice> choices,
    required VoidCallback? onTap,
  }) {
    if (id == null || id.isEmpty) {
      return MatchPickVersusTeam(
        name: 'TBD',
        caption: caption,
        placeholder: true,
        showEditBadge: onTap != null,
        onTap: onTap,
      );
    }
    final choice = choices.where((item) => item.id == id).firstOrNull;
    return MatchPickVersusTeam(
      name: choice?.name ?? 'Team',
      logoUrl: choice?.logo ?? '',
      caption: caption,
      placeholder: choice == null,
      showEditBadge: onTap != null,
      onTap: onTap,
    );
  }

  Future<void> _pickSide({
    required String title,
    required String? selected,
    required String? other,
    required List<_TeamChoice> choices,
    required TournamentDetailController controller,
    required ValueChanged<String?> onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TeamPickerSheet(
          title: title,
          selectedId: selected ?? '',
          options: _optionsFor(
            choices,
            selected: selected,
            other: other,
            controller: controller,
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    onPicked(_emptyToNull(picked));
  }

  List<_TeamChoice> _choices(TournamentDetailController controller) {
    final byId = <String, _TeamChoice>{};
    for (final entry in controller.entries) {
      if (entry.status != 'accepted' || entry.teamId.isEmpty) continue;
      byId[entry.teamId] = _TeamChoice(
        id: entry.teamId,
        name: entry.teamName,
        logo: entry.teamLogo,
      );
    }
    _rememberFixtureTeam(
      byId,
      widget.fixture.fromTeamId,
      widget.fixture.match.fromTeamHelper,
    );
    _rememberFixtureTeam(
      byId,
      widget.fixture.toTeamId,
      widget.fixture.match.toTeamHelper,
    );
    final choices = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return choices;
  }

  void _rememberFixtureTeam(
    Map<String, _TeamChoice> byId,
    String teamId,
    TeamRefFieldInstance team,
  ) {
    if (teamId.isEmpty) return;
    final name = team.bracketLabel;
    final logo = team.getSubsetModel()?.logo ?? '';
    final existing = byId[teamId];
    if (existing == null) {
      byId[teamId] = _TeamChoice(id: teamId, name: name, logo: logo);
      return;
    }
    if (existing.logo.isEmpty && logo.isNotEmpty) {
      byId[teamId] = _TeamChoice(id: teamId, name: existing.name, logo: logo);
    }
  }

  List<_TeamChoice> _optionsFor(
    List<_TeamChoice> choices, {
    required String? selected,
    required String? other,
    required TournamentDetailController controller,
  }) {
    final taken = _takenInRound(controller);
    final options = <_TeamChoice>[const _TeamChoice(id: '', name: 'TBD')];
    for (final choice in choices) {
      if (choice.id.isEmpty) continue;
      final blocked = taken.contains(choice.id) && choice.id != selected;
      final sameMatch = choice.id == other;
      if ((blocked || sameMatch) && choice.id != selected) continue;
      options.add(choice);
    }
    return options;
  }

  bool _pairAlreadyScheduled(TournamentDetailController controller) {
    final home = _homeId;
    final away = _awayId;
    if (widget.fixture.stage != 'league' ||
        home == null ||
        home.isEmpty ||
        away == null ||
        away.isEmpty) {
      return false;
    }
    final group = widget.fixture.groupLabel;
    for (final other in controller.fixtures) {
      if (other.id == widget.fixture.id || other.stage != 'league') continue;
      if (other.groupLabel != group) continue;
      if (_roundSlotFree(other.match.status)) continue;
      final same = (other.fromTeamId == home && other.toTeamId == away) ||
          (other.fromTeamId == away && other.toTeamId == home);
      if (same) return true;
    }
    return false;
  }

  Set<String> _takenInRound(TournamentDetailController controller) {
    final ids = <String>{};
    for (final other in controller.fixtures) {
      if (other.id == widget.fixture.id) continue;
      if (other.stage != 'knockout' || other.round != widget.fixture.round) {
        continue;
      }
      if (_roundSlotFree(other.match.status)) continue;
      if (other.fromTeamId.isNotEmpty) ids.add(other.fromTeamId);
      if (other.toTeamId.isNotEmpty) ids.add(other.toTeamId);
    }
    return ids;
  }
}

bool _roundSlotFree(TeamMatchStatus status) {
  return switch (status) {
    TeamMatchStatus.cancelled ||
    TeamMatchStatus.abandoned ||
    TeamMatchStatus.rejected ||
    TeamMatchStatus.expired => true,
    _ => false,
  };
}

String? _emptyToNull(String id) => id.isEmpty ? null : id;

class _TeamPickerSheet extends StatelessWidget {
  const _TeamPickerSheet({
    required this.title,
    required this.selectedId,
    required this.options,
  });

  final String title;
  final String selectedId;
  final List<_TeamChoice> options;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final choice in options)
                    _TeamPickerTile(
                      choice: choice,
                      selected: choice.id == selectedId,
                      onTap: () => Navigator.pop(context, choice.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamPickerTile extends StatelessWidget {
  const _TeamPickerTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _TeamChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tbd = choice.id.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? const Color(AppColors.primaryColor).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (tbd)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      AppIcons.teamPlaceholder,
                      size: 20,
                      color: Color(AppColors.primaryColor),
                    ),
                  )
                else
                  TeamLogo(url: choice.logo, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choice.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontStyle: tbd ? FontStyle.italic : FontStyle.normal,
                      color: const Color(AppColors.textColor),
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 22,
                    color: Color(AppColors.primaryColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
