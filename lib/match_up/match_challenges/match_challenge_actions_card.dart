import 'package:flutter/material.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/model/team_model.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

enum _MatchResultChoice { draw, fromWins, toWins, markOngoing }

/// Cancel match + record result actions, dialogs, and API calls.
class MatchChallengeActionsCard extends StatefulWidget {
  const MatchChallengeActionsCard({
    super.key,
    required this.match,
    required this.myTeamId,
    required this.onMatchUpdated,
    required this.onInternalBusyChanged,
  });

  final TeamMatchModel match;
  final String myTeamId;
  final void Function(TeamMatchModel updated) onMatchUpdated;
  final void Function(bool busy) onInternalBusyChanged;

  @override
  State<MatchChallengeActionsCard> createState() =>
      _MatchChallengeActionsCardState();
}

class _MatchChallengeActionsCardState extends State<MatchChallengeActionsCard> {
  final MatchmakingService _matchmaking = MatchmakingService();
  bool _isCancelling = false;
  bool _isRecordingResult = false;

  bool get _apiBusy => _isCancelling || _isRecordingResult;

  bool get canCancelMatch {
    return switch (widget.match.status) {
      TeamMatchStatus.requested ||
      TeamMatchStatus.cancelled ||
      TeamMatchStatus.rejected ||
      TeamMatchStatus.expired ||
      TeamMatchStatus.completed ||
      TeamMatchStatus.draw => false,
      _ => true,
    };
  }

  bool get canRecordMatchResult {
    return switch (widget.match.status) {
      TeamMatchStatus.accepted ||
      TeamMatchStatus.scheduleFinalized ||
      TeamMatchStatus.ongoing => true,
      _ => false,
    };
  }

  @override
  void dispose() {
    widget.onInternalBusyChanged(false);
    super.dispose();
  }

  void _syncBusy() {
    widget.onInternalBusyChanged(_isCancelling || _isRecordingResult);
  }

  Future<void> _onCancel() async {
    if (_apiBusy || widget.myTeamId.isEmpty) return;
    if (widget.match.id == null || widget.match.id!.isEmpty) return;

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel this match?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This will cancel the challenge for both teams. You can add an optional note below.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Reason (optional)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Cancel match',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        );
      },
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    _syncBusy();
    final updated = await _matchmaking.cancel(
      widget.match.id!,
      CancelNegotiationRequest(
        actorTeamId: widget.myTeamId,
        reason: reason.isEmpty ? null : reason,
      ),
    );
    if (!mounted) return;
    setState(() => _isCancelling = false);
    _syncBusy();

    if (updated == null) {
      AppSnackbar.error(
        title: 'Could not cancel',
        message: 'Please try again later.',
      );
      return;
    }
    widget.onMatchUpdated(updated);
    AppSnackbar.success(
      title: 'Match cancelled',
      message: 'This challenge has been cancelled.',
    );
  }

  Future<void> _onRecordResult() async {
    if (_apiBusy || widget.myTeamId.isEmpty) return;
    if (widget.match.id == null || widget.match.id!.isEmpty) return;

    final fromName = widget.match.fromTeamHelper.getDisplayName();
    final toName = widget.match.toTeamHelper.getDisplayName();
    final fromId = widget.match.fromTeamHelper.getId();
    final toId = widget.match.toTeamHelper.getId();
    if (fromId == null || fromId.isEmpty || toId == null || toId.isEmpty) {
      AppSnackbar.error(
        title: 'Cannot record result',
        message: 'Team information is missing.',
      );
      return;
    }

    final showOngoing =
        widget.match.status == TeamMatchStatus.scheduleFinalized;

    final choice = await showDialog<_MatchResultChoice>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Match result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showOngoing)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Mark as ongoing'),
                    subtitle: const Text('Match has started'),
                    onTap: () =>
                        Navigator.pop(ctx, _MatchResultChoice.markOngoing),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.balance),
                  title: const Text('Draw'),
                  onTap: () => Navigator.pop(ctx, _MatchResultChoice.draw),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.military_tech_outlined),
                  title: Text('$fromName won'),
                  onTap: () => Navigator.pop(ctx, _MatchResultChoice.fromWins),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.military_tech_outlined),
                  title: Text('$toName won'),
                  onTap: () => Navigator.pop(ctx, _MatchResultChoice.toWins),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    if (choice == null || !mounted) return;

    final MatchResultOutcome outcome;
    final String? winnerTeam;
    switch (choice) {
      case _MatchResultChoice.draw:
        outcome = MatchResultOutcome.draw;
        winnerTeam = null;
        break;
      case _MatchResultChoice.fromWins:
        outcome = MatchResultOutcome.completed;
        winnerTeam = fromId;
        break;
      case _MatchResultChoice.toWins:
        outcome = MatchResultOutcome.completed;
        winnerTeam = toId;
        break;
      case _MatchResultChoice.markOngoing:
        outcome = MatchResultOutcome.ongoing;
        winnerTeam = null;
        break;
    }

    setState(() => _isRecordingResult = true);
    _syncBusy();
    final updated = await _matchmaking.recordMatchResult(
      widget.match.id!,
      RecordMatchResultRequest(
        actorTeamId: widget.myTeamId,
        outcome: outcome,
        winnerTeam: winnerTeam,
      ),
    );
    if (!mounted) return;
    setState(() => _isRecordingResult = false);
    _syncBusy();

    if (updated == null) {
      AppSnackbar.error(
        title: 'Could not save result',
        message: 'Please try again later.',
      );
      return;
    }
    widget.onMatchUpdated(updated);

    if (outcome == MatchResultOutcome.ongoing &&
        updated.id != null &&
        updated.id!.isNotEmpty) {
      try {
        if (mounted) {
          final sportLabel = updated.sportType == TeamSportType.cricket
              ? 'Cricket'
              : 'Football';
          AppSnackbar.success(
            title: 'Live scoring connected',
            message: '$sportLabel scoring session is ready.',
          );
        }
      } catch (_) {
        if (mounted) {
          AppSnackbar.error(
            title: 'Scoring connection failed',
            message: 'Could not connect to realtime scoring.',
          );
        }
      }
    }

    AppSnackbar.success(
      title: 'Result saved',
      message: 'The match has been updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!canCancelMatch && !canRecordMatchResult) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (canRecordMatchResult)
          Expanded(
            child: _ActionChipButton(
              icon: Icons.emoji_events_outlined,
              label: 'Record result',
              busy: _isRecordingResult,
              enabled: !_apiBusy,
              onTap: _onRecordResult,
            ),
          ),
        if (canRecordMatchResult && canCancelMatch) const SizedBox(width: 10),
        if (canCancelMatch)
          Expanded(
            child: _ActionChipButton(
              icon: Icons.event_busy,
              label: 'Cancel',
              busy: _isCancelling,
              enabled: !_apiBusy,
              onTap: _onCancel,
              foreground: Colors.red.shade800,
              background: Colors.red.shade50,
              border: Colors.red.shade200,
            ),
          ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.foreground,
    this.background,
    this.border,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;
  final Color? foreground;
  final Color? background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? const Color(AppColors.primaryColor);
    final bg = background ??
        const Color(AppColors.primaryColor).withValues(alpha: 0.08);
    final bd = border ??
        const Color(AppColors.primaryColor).withValues(alpha: 0.22);
    final muted = !enabled;

    return Material(
      color: muted ? bg.withValues(alpha: 0.5) : bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled && !busy ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: muted ? bd.withValues(alpha: 0.5) : bd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else
                Icon(icon, size: 18, color: muted ? fg.withValues(alpha: 0.5) : fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: muted ? fg.withValues(alpha: 0.5) : fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
