import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../match_up/announced_players/model/announced_player_model.dart';
import '../../../match_up/model/team_match_model.dart';
import '../../../scoring/common/lineup_helpers.dart';
import '../announced_player_list_tile.dart';

/// Result of a cricket substitution picker.
class CricketSubstitutionResult {
  const CricketSubstitutionResult({
    required this.teamId,
    required this.playerOffParticipantId,
    required this.playerOnParticipantId,
  });

  final String teamId;
  final String playerOffParticipantId;
  final String playerOnParticipantId;
}

/// Bottom sheet: team → player off (active) → player on (bench).
class CricketSubstitutionSheet {
  CricketSubstitutionSheet._();

  static Future<CricketSubstitutionResult?> show({
    required BuildContext context,
    required TeamMatchModel match,
    required String fromTeamId,
    required String toTeamId,
    required String Function(String teamId) teamLabelForId,
  }) {
    return showModalBottomSheet<CricketSubstitutionResult>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _CricketSubstitutionSheetBody(
        match: match,
        fromTeamId: fromTeamId,
        toTeamId: toTeamId,
        teamLabelForId: teamLabelForId,
        sheetModalContext: sheetContext,
      ),
    );
  }
}

class _CricketSubstitutionSheetBody extends StatefulWidget {
  const _CricketSubstitutionSheetBody({
    required this.match,
    required this.fromTeamId,
    required this.toTeamId,
    required this.teamLabelForId,
    required this.sheetModalContext,
  });

  final TeamMatchModel match;
  final String fromTeamId;
  final String toTeamId;
  final String Function(String teamId) teamLabelForId;
  final BuildContext sheetModalContext;

  @override
  State<_CricketSubstitutionSheetBody> createState() =>
      _CricketSubstitutionSheetBodyState();
}

class _CricketSubstitutionSheetBodyState
    extends State<_CricketSubstitutionSheetBody> {
  String? _teamId;
  String? _playerOffId;
  String? _playerOnId;

  static const TextStyle _titleStyle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: Color(AppColors.textColor),
  );

  static const TextStyle _labelStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(AppColors.textColor),
  );

  List<AnnouncedPlayerModel> _activeForTeam(String teamId) =>
      activePlayersForTeam(widget.match, teamId);

  List<AnnouncedPlayerModel> _benchForTeam(String teamId) {
    final activeIds = _activeForTeam(teamId)
        .map((p) => p.participantId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    return widget.match.announcedPlayers
        .where((p) {
          final tid = p.teamIdHelper.getId() ?? '';
          final pid = p.participantId;
          return tid == teamId &&
              pid != null &&
              pid.isNotEmpty &&
              !activeIds.contains(pid);
        })
        .toList();
  }

  bool get _canSubmit =>
      _teamId != null &&
      _teamId!.isNotEmpty &&
      _playerOffId != null &&
      _playerOffId!.isNotEmpty &&
      _playerOnId != null &&
      _playerOnId!.isNotEmpty &&
      _playerOffId != _playerOnId;

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
            const Text('Substitution', style: _titleStyle),
            const SizedBox(height: 16),
            const Text('Team', style: _labelStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TeamTile(
                    label: widget.teamLabelForId(widget.fromTeamId),
                    selected: _teamId == widget.fromTeamId,
                    onTap: () => setState(() {
                      _teamId = widget.fromTeamId;
                      _playerOffId = null;
                      _playerOnId = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TeamTile(
                    label: widget.teamLabelForId(widget.toTeamId),
                    selected: _teamId == widget.toTeamId,
                    onTap: () => setState(() {
                      _teamId = widget.toTeamId;
                      _playerOffId = null;
                      _playerOnId = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _playerSection(
              label: 'Player off',
              players: _teamId == null || _teamId!.isEmpty
                  ? const []
                  : _activeForTeam(_teamId!),
              selectedUserId: _playerOffId,
              onSelected: (id) => setState(() {
                _playerOffId = id;
                if (_playerOnId == id) _playerOnId = null;
              }),
              emptyHint: _teamId == null || _teamId!.isEmpty
                  ? 'Select team first'
                  : 'No active players',
            ),
            const SizedBox(height: 8),
            _playerSection(
              label: 'Player on',
              players: _teamId == null || _teamId!.isEmpty
                  ? const []
                  : _benchForTeam(_teamId!),
              selectedUserId: _playerOnId,
              onSelected: (id) => setState(() => _playerOnId = id),
              emptyHint: _teamId == null || _teamId!.isEmpty
                  ? 'Select team first'
                  : 'No bench players',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(AppColors.primaryColor),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
              ),
              child: const Text('Record substitution'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerSection({
    required String label,
    required List<AnnouncedPlayerModel> players,
    required String? selectedUserId,
    required ValueChanged<String> onSelected,
    required String emptyHint,
  }) {
    if (_teamId == null || _teamId!.isEmpty) {
      return Text(
        emptyHint,
        style: const TextStyle(color: Color(AppColors.textSecondaryColor)),
      );
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
              color: const Color(
                AppColors.dividerColor,
              ).withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            selectedName ?? (players.isEmpty ? emptyHint : 'Tap to select'),
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
                  return AnnouncedPlayerListTile.fromPlayer(
                    p,
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

  void _submit() {
    Navigator.pop(
      context,
      CricketSubstitutionResult(
        teamId: _teamId!,
        playerOffParticipantId: _playerOffId!,
        playerOnParticipantId: _playerOnId!,
      ),
    );
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
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? const Color(AppColors.primaryColor).withValues(alpha: 0.45)
              : const Color(AppColors.dividerColor).withValues(alpha: 0.85),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
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
