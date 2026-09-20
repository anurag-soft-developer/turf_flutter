import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../scoring/football/model/football_match_event_model.dart';
import '../../../scoring/football/model/football_scoring_models.dart';
import '../../../scoring/football/util/football_scoring_helpers.dart';

/// Bottom sheet to collect players/teams for a football scoring event.
class FootballEventPlayerSheet {
  FootballEventPlayerSheet._();

  static Future<FootballEventPayload?> show({
    required BuildContext context,
    required FootballEventKind kind,
    required TeamMatchModel match,
    required String fromTeamId,
    required String toTeamId,
    required String Function(String teamId) teamLabelForId,
  }) {
    return showModalBottomSheet<FootballEventPayload>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _FootballEventSheetBody(
        kind: kind,
        match: match,
        fromTeamId: fromTeamId,
        toTeamId: toTeamId,
        teamLabelForId: teamLabelForId,
        sheetModalContext: sheetContext,
      ),
    );
  }
}

class _FootballEventSheetBody extends StatefulWidget {
  const _FootballEventSheetBody({
    required this.kind,
    required this.match,
    required this.fromTeamId,
    required this.toTeamId,
    required this.teamLabelForId,
    required this.sheetModalContext,
  });

  final FootballEventKind kind;
  final TeamMatchModel match;
  final String fromTeamId;
  final String toTeamId;
  final String Function(String teamId) teamLabelForId;
  final BuildContext sheetModalContext;

  @override
  State<_FootballEventSheetBody> createState() => _FootballEventSheetBodyState();
}

class _FootballEventSheetBodyState extends State<_FootballEventSheetBody> {
  String? _teamId;
  String? _beneficiaryTeamId;
  String? _playerUserId;
  String? _secondPlayerUserId;

  bool get _needsBeneficiaryTeam =>
      widget.kind == FootballEventKind.goal ||
      widget.kind == FootballEventKind.ownGoal ||
      widget.kind == FootballEventKind.penaltyScored;

  bool get _needsTeamOnly =>
      widget.kind == FootballEventKind.yellowCard ||
      widget.kind == FootballEventKind.redCard ||
      widget.kind == FootballEventKind.penaltyMissed;

  static const TextStyle _titleStyle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: Color(AppColors.textColor),
  );

  static const TextStyle _labelStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textColor),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(eventKindLabel(widget.kind), style: _titleStyle),
            const SizedBox(height: 16),
            if (_needsBeneficiaryTeam) ...[
              const Text('Scoring team', style: _labelStyle),
              const SizedBox(height: 8),
              _teamPicker(
                selectedId: _beneficiaryTeamId,
                onSelected: (id) => setState(() {
                  _beneficiaryTeamId = id;
                  _playerUserId = null;
                  _secondPlayerUserId = null;
                }),
              ),
              const SizedBox(height: 12),
            ],
            if (_needsTeamOnly ||
                widget.kind == FootballEventKind.substitution) ...[
              const Text('Team', style: _labelStyle),
              const SizedBox(height: 8),
              _teamPicker(
                selectedId: _teamId,
                onSelected: (id) => setState(() {
                  _teamId = id;
                  _playerUserId = null;
                  _secondPlayerUserId = null;
                }),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.kind == FootballEventKind.goal) ...[
              _playerSection(
                label: 'Scorer',
                teamId: _beneficiaryTeamId,
                selectedUserId: _playerUserId,
                onSelected: (id) => setState(() => _playerUserId = id),
              ),
              const SizedBox(height: 8),
              _playerSection(
                label: 'Assist (optional)',
                teamId: _beneficiaryTeamId,
                selectedUserId: _secondPlayerUserId,
                onSelected: (id) => setState(() => _secondPlayerUserId = id),
                optional: true,
              ),
            ],
            if (widget.kind == FootballEventKind.ownGoal) ...[
              _playerSection(
                label: 'Conceding player',
                teamId: _otherTeam(_beneficiaryTeamId),
                selectedUserId: _playerUserId,
                onSelected: (id) => setState(() => _playerUserId = id),
              ),
            ],
            if (widget.kind == FootballEventKind.yellowCard ||
                widget.kind == FootballEventKind.redCard) ...[
              _playerSection(
                label: 'Player',
                teamId: _teamId,
                selectedUserId: _playerUserId,
                onSelected: (id) => setState(() => _playerUserId = id),
              ),
            ],
            if (widget.kind == FootballEventKind.substitution) ...[
              _playerSection(
                label: 'Player off',
                teamId: _teamId,
                selectedUserId: _playerUserId,
                onSelected: (id) => setState(() => _playerUserId = id),
              ),
              const SizedBox(height: 8),
              _playerSection(
                label: 'Player on',
                teamId: _teamId,
                selectedUserId: _secondPlayerUserId,
                onSelected: (id) => setState(() => _secondPlayerUserId = id),
                excludeUserId: _playerUserId,
              ),
            ],
            if (widget.kind == FootballEventKind.penaltyScored) ...[
              _playerSection(
                label: 'Taker',
                teamId: _beneficiaryTeamId,
                selectedUserId: _playerUserId,
                onSelected: (id) => setState(() => _playerUserId = id),
              ),
            ],
            if (widget.kind == FootballEventKind.penaltyMissed) ...[
              _playerSection(
                label: 'Taker',
                teamId: _teamId,
                selectedUserId: _playerUserId,
                onSelected: (id) => setState(() => _playerUserId = id),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(AppColors.primaryColor),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
              ),
              child: const Text('Record event'),
            ),
          ],
        ),
      ),
    );
  }

  String? _otherTeam(String? beneficiaryId) {
    if (beneficiaryId == null || beneficiaryId.isEmpty) return null;
    if (footballTeamIdsMatch(beneficiaryId, widget.fromTeamId)) {
      return widget.toTeamId;
    }
    return widget.fromTeamId;
  }

  Widget _teamPicker({
    required String? selectedId,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: [
        Expanded(
          child: _TeamTile(
            label: widget.teamLabelForId(widget.fromTeamId),
            selected: footballTeamIdsMatch(selectedId, widget.fromTeamId),
            onTap: () => onSelected(widget.fromTeamId),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TeamTile(
            label: widget.teamLabelForId(widget.toTeamId),
            selected: footballTeamIdsMatch(selectedId, widget.toTeamId),
            onTap: () => onSelected(widget.toTeamId),
          ),
        ),
      ],
    );
  }

  Widget _playerSection({
    required String label,
    required String? teamId,
    required String? selectedUserId,
    required ValueChanged<String> onSelected,
    bool optional = false,
    String? excludeUserId,
  }) {
    if (teamId == null || teamId.isEmpty) {
      return Text(
        optional ? '$label — select team first' : 'Select team first',
        style: const TextStyle(color: Color(AppColors.textSecondaryColor)),
      );
    }
    var players = playingXiForTeam(widget.match, teamId);
    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      players = players
          .where((p) => p.participantId != excludeUserId)
          .toList();
    }
    final selectedName = players
        .where((p) => p.participantId == selectedUserId)
        .map((p) => p.name)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: players.isEmpty
              ? null
              : () async {
                  final picked = await _pickPlayer(
                    widget.sheetModalContext,
                    label,
                    players,
                  );
                  if (picked != null && picked.isNotEmpty) {
                    onSelected(picked);
                  }
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(AppColors.textColor),
            disabledForegroundColor: const Color(AppColors.textSecondaryColor),
            side: BorderSide(
              color: const Color(AppColors.dividerColor).withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            selectedName ??
                (optional ? 'Tap to select (optional)' : 'Tap to select'),
            style: TextStyle(
              color: selectedName != null
                  ? const Color(AppColors.textColor)
                  : const Color(AppColors.textSecondaryColor),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _pickPlayer(
    BuildContext sheetContext,
    String title,
    List<AnnouncedPlayerModel> players,
  ) async {
    final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.45;
    final picked = await showModalBottomSheet<AnnouncedPlayerModel>(
      context: sheetContext,
      useRootNavigator: false,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(title, style: _titleStyle),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                itemBuilder: (_, i) {
                  final p = players[i];
                  return ListTile(
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        color: Color(AppColors.textColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    final id = picked?.participantId;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  bool get _canSubmit {
    switch (widget.kind) {
      case FootballEventKind.goal:
        return _beneficiaryTeamId != null &&
            _beneficiaryTeamId!.isNotEmpty &&
            _playerUserId != null &&
            _playerUserId!.isNotEmpty;
      case FootballEventKind.ownGoal:
        return _beneficiaryTeamId != null &&
            _beneficiaryTeamId!.isNotEmpty &&
            _playerUserId != null &&
            _playerUserId!.isNotEmpty;
      case FootballEventKind.yellowCard:
      case FootballEventKind.redCard:
      case FootballEventKind.penaltyMissed:
        return _teamId != null &&
            _teamId!.isNotEmpty &&
            _playerUserId != null &&
            _playerUserId!.isNotEmpty;
      case FootballEventKind.substitution:
        return _teamId != null &&
            _teamId!.isNotEmpty &&
            _playerUserId != null &&
            _playerUserId!.isNotEmpty &&
            _secondPlayerUserId != null &&
            _secondPlayerUserId!.isNotEmpty &&
            _playerUserId != _secondPlayerUserId;
      case FootballEventKind.penaltyScored:
        return _beneficiaryTeamId != null &&
            _beneficiaryTeamId!.isNotEmpty &&
            _playerUserId != null &&
            _playerUserId!.isNotEmpty;
    }
  }

  void _submit() {
    final payload = switch (widget.kind) {
      FootballEventKind.goal => GoalPayload(
        beneficiaryTeamId: _beneficiaryTeamId!,
        scorerUserId: _playerUserId!,
        assistUserId: _secondPlayerUserId,
      ),
      FootballEventKind.ownGoal => OwnGoalPayload(
        beneficiaryTeamId: _beneficiaryTeamId!,
        concedingPlayerUserId: _playerUserId!,
      ),
      FootballEventKind.yellowCard => YellowCardPayload(
        teamId: _teamId!,
        playerUserId: _playerUserId!,
      ),
      FootballEventKind.redCard => RedCardPayload(
        teamId: _teamId!,
        playerUserId: _playerUserId!,
      ),
      FootballEventKind.substitution => SubstitutionPayload(
        teamId: _teamId!,
        playerOffUserId: _playerUserId!,
        playerOnUserId: _secondPlayerUserId!,
      ),
      FootballEventKind.penaltyScored => PenaltyScoredPayload(
        beneficiaryTeamId: _beneficiaryTeamId!,
        takerUserId: _playerUserId!,
      ),
      FootballEventKind.penaltyMissed => PenaltyMissedPayload(
        teamId: _teamId!,
        takerUserId: _playerUserId!,
      ),
    };
    Navigator.pop(context, payload);
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(AppColors.primaryColor).withValues(alpha: 0.12)
          : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? const Color(AppColors.primaryColor)
                  : const Color(AppColors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}
