import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/challenges/challenge_messages_placeholder.dart';
import '../../components/challenges/match_challenge_respond_actions.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../components/challenges/praposals/propose_time_slot_sheet.dart';
import '../../components/challenges/praposals/propose_turf_sheet.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../turf/model/turf_model.dart';
import '../../turf/turf_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import 'match_challenges_controller.dart';
import 'match_challenge_actions_card.dart';
import 'match_challenge_versus_header.dart';

class MatchChallengeDetailScreen extends StatefulWidget {
  final TeamMatchModel match;
  final bool isIncoming;

  const MatchChallengeDetailScreen({
    super.key,
    required this.match,
    required this.isIncoming,
  });

  @override
  State<MatchChallengeDetailScreen> createState() =>
      _MatchChallengeDetailScreenState();
}

class _MatchChallengeDetailScreenState extends State<MatchChallengeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TeamMatchModel _match;
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TurfService _turfService = TurfService();
  bool _isUpdatingSlot = false;
  bool _isUpdatingTurf = false;
  bool _isRejectingChallenge = false;
  bool _isAcceptingChallenge = false;

  /// Busy while cancel/result API runs in [MatchChallengeActionsCard].
  bool _actionsChildBusy = false;
  List<TurfModel> _myTurfs = const [];

  bool get _actionBusy =>
      _isUpdatingSlot ||
      _isUpdatingTurf ||
      _isRejectingChallenge ||
      _isAcceptingChallenge ||
      _actionsChildBusy;

  /// Avoids [setState] while the build/layout lock is held (e.g. child
  /// [dispose] or right after a nested [setState] in [MatchChallengeActionsCard]).
  void _scheduleMatchUpdate(TeamMatchModel m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _match = m);
      _trySyncChallengesList(m);
    });
  }

  void _trySyncChallengesList(TeamMatchModel updated) {
    if (!Get.isRegistered<MatchChallengesController>()) return;
    Get.find<MatchChallengesController>().applyMatchUpdateFromDetail(updated);
  }

  void _scheduleActionsChildBusy(bool busy) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_actionsChildBusy == busy) return;
      setState(() => _actionsChildBusy = busy);
    });
  }

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Allow setting or changing time/turf while negotiating or after schedule is finalized
  /// (e.g. correction before the match is live).
  bool get _canEditSchedule {
    return switch (_match.status) {
      TeamMatchStatus.requested => true,
      TeamMatchStatus.accepted => true,
      TeamMatchStatus.negotiating => true,
      TeamMatchStatus.scheduleFinalized => true,
      _ => false,
    };
  }

  String get _myTeamId => widget.isIncoming
      ? (_match.toTeamHelper.getId() ?? '')
      : (_match.fromTeamHelper.getId() ?? '');

  bool get _isExpiredByDeadline {
    final expiresAt = _match.expiresAt;
    return expiresAt != null && DateTime.now().isAfter(expiresAt.toLocal());
  }

  bool get _canRespondToChallenge {
    return widget.isIncoming &&
        _match.status == TeamMatchStatus.requested &&
        !_isExpiredByDeadline;
  }

  Future<void> _respondToChallenge(MatchResponseAction action) async {
    if (_isUpdatingSlot || _isUpdatingTurf || _actionsChildBusy) return;
    if (_isRejectingChallenge || _isAcceptingChallenge) return;
    if (!_canRespondToChallenge) return;
    if (_match.id == null || _match.id!.isEmpty || _myTeamId.isEmpty) return;

    setState(() {
      if (action == MatchResponseAction.reject) {
        _isRejectingChallenge = true;
      } else {
        _isAcceptingChallenge = true;
      }
    });
    final updated = await _matchmakingService.respond(
      _match.id!,
      RespondMatchRequest(actorTeamId: _myTeamId, action: action),
    );
    if (!mounted) return;
    setState(() {
      _isRejectingChallenge = false;
      _isAcceptingChallenge = false;
    });

    if (updated == null) {
      AppSnackbar.error(
        title: action == MatchResponseAction.accept
            ? 'Could not accept'
            : 'Could not reject',
        message: 'Try again later.',
      );
      return;
    }
    setState(() => _match = updated);
    _trySyncChallengesList(updated);
    AppSnackbar.success(
      title: action == MatchResponseAction.accept
          ? 'Challenge accepted'
          : 'Challenge rejected',
      message: action == MatchResponseAction.accept
          ? 'You can continue scheduling now.'
          : 'The challenge was declined.',
    );
  }

  /// Schedule edits (time/turf) while not running cancel/result actions.
  bool get _canUseScheduleControls => _canEditSchedule && !_actionsChildBusy;

  Future<void> _setTimeSlot() async {
    if (_actionBusy) return;
    if (_match.id == null || _match.id!.isEmpty || _myTeamId.isEmpty) return;

    final selected = await showModalBottomSheet<ProposeScheduleTimeSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposeTimeSlotSheet(),
    );
    if (selected == null) return;

    setState(() => _isUpdatingSlot = true);
    final updated = await _matchmakingService.updateRequest(
      _match.id!,
      UpdateTeamMatchRequest(
        slot: TeamMatchTimeSlot(
          startTime: selected.startTime,
          endTime: selected.endTime,
        ),
        selfAcceptTeamId: _myTeamId,
      ),
    );
    if (!mounted) return;
    setState(() => _isUpdatingSlot = false);

    if (updated == null) {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'Could not set the time slot. Please try again.',
      );
      return;
    }
    setState(() => _match = updated);
    _trySyncChallengesList(updated);
    AppSnackbar.success(
      title: 'Time updated',
      message: 'The match time has been saved.',
    );
  }

  Future<void> _setTurf() async {
    if (_actionBusy) return;
    if (_match.id == null || _match.id!.isEmpty || _myTeamId.isEmpty) return;

    if (_myTurfs.isEmpty) {
      final response = await _turfService.getMyTurfs(limit: 100);
      if (!mounted) return;
      setState(() {
        _myTurfs = response?.data ?? const [];
      });
    }

    if (_myTurfs.isEmpty) {
      AppSnackbar.info(
        title: 'No turfs found',
        message: 'Create a turf first before choosing a venue.',
      );
      return;
    }

    final selectedTurfId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProposeTurfSheet(turfs: _myTurfs),
    );
    if (selectedTurfId == null || selectedTurfId.isEmpty) return;

    setState(() => _isUpdatingTurf = true);
    final updated = await _matchmakingService.updateRequest(
      _match.id!,
      UpdateTeamMatchRequest(
        turfId: selectedTurfId,
        selfAcceptTeamId: _myTeamId,
      ),
    );
    if (!mounted) return;
    setState(() => _isUpdatingTurf = false);

    if (updated == null) {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'Could not set the turf. Please try again.',
      );
      return;
    }
    setState(() => _match = updated);
    _trySyncChallengesList(updated);
    AppSnackbar.success(
      title: 'Turf updated',
      message: 'The venue has been saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Challenge Details')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSegmentedTabs(
              controller: _tabController,
              padding: EdgeInsets.zero,
              items: const [
                AppTabItem(label: 'Details'),
                AppTabItem(label: 'Messages'),
              ],
            ),
          ),
          Expanded(
            child: AppSegmentedTabView(
              controller: _tabController,
              children: [_buildDetailsTab(), _buildMessagesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final acceptedSlotCandidates = _match.proposedSlots.where((slot) {
      if (_match.selectedSlotProposalId != null) {
        return slot.proposalId == _match.selectedSlotProposalId;
      }
      return slot.status == MatchProposalStatus.accepted;
    });
    final acceptedSlot = acceptedSlotCandidates.isEmpty
        ? null
        : acceptedSlotCandidates.first;
    final acceptedTurfCandidates = _match.proposedTurfs.where((turf) {
      if (_match.selectedTurfProposalId != null) {
        return turf.proposalId == _match.selectedTurfProposalId;
      }
      return turf.status == MatchProposalStatus.accepted;
    });
    final acceptedTurf = acceptedTurfCandidates.isEmpty
        ? null
        : acceptedTurfCandidates.first;

    final hasSlot = acceptedSlot != null;
    final hasTurf = acceptedTurf != null;
    final timeSummary = acceptedSlot != null
        ? '${_fmt(acceptedSlot.slot.startTime)} – ${_fmt(acceptedSlot.slot.endTime)}'
        : 'Not set';
    final turfSummary = acceptedTurf != null
        ? acceptedTurf.turfIdHelper.getDisplayName()
        : 'Not set';
    final bookingRef = _match.turfBookingIdHelper;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            _InfoCard(
              title: '',
              child: MatchChallengeVersusHeader(match: _match),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final infoTiles = <Widget>[
                  _InfoTile(
                    icon: Icons.sports_soccer,
                    label: 'Sport type',
                    value:
                        _match.sportType.name.capitalizeFirst ??
                        _match.sportType.name,
                  ),
                  _InfoTile(
                    icon: Icons.flag_outlined,
                    label: 'Match status',
                    value:
                        _match.status.name.capitalizeFirst ??
                        _match.status.name,
                  ),
                  if (_match.turfBookingId != null)
                    _InfoTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Turf booking',
                      value: bookingRef.getDisplayName(),
                    ),
                ];
                final tileWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: infoTiles
                      .map((tile) => SizedBox(width: tileWidth, child: tile))
                      .toList(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Schedule',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScheduleLine(
                icon: Icons.schedule,
                label: 'Time',
                value: timeSummary,
                canEdit: _canUseScheduleControls,
                isLoading: _isUpdatingSlot,
                otherFieldBusy: _isUpdatingTurf || _actionsChildBusy,
                onEditPressed: _setTimeSlot,
                editTooltip: hasSlot ? 'Edit time' : 'Set time',
                editIcon: hasSlot
                    ? Icons.edit_outlined
                    : Icons.event_available_outlined,
              ),
              const SizedBox(height: 12),
              _ScheduleLine(
                icon: Icons.grass,
                label: 'Turf',
                value: turfSummary,
                canEdit: _canUseScheduleControls,
                isLoading: _isUpdatingTurf,
                otherFieldBusy: _isUpdatingSlot || _actionsChildBusy,
                onEditPressed: _setTurf,
                editTooltip: hasTurf ? 'Edit turf' : 'Set turf',
                editIcon: hasTurf
                    ? Icons.edit_outlined
                    : Icons.add_location_alt_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MatchChallengeActionsCard(
          match: _match,
          myTeamId: _myTeamId,
          onMatchUpdated: _scheduleMatchUpdate,
          onInternalBusyChanged: _scheduleActionsChildBusy,
        ),
        if (_canRespondToChallenge) ...[
          const SizedBox(height: 12),
          MatchChallengeRespondActions(
            isRejecting: _isRejectingChallenge,
            isAccepting: _isAcceptingChallenge,
            enabled: !_isUpdatingSlot && !_isUpdatingTurf && !_actionsChildBusy,
            onReject: () => _respondToChallenge(MatchResponseAction.reject),
            onAccept: () => _respondToChallenge(MatchResponseAction.accept),
          ),
        ],
      ],
    );
  }

  Widget _buildMessagesTab() {
    return const ChallengeMessagesPlaceholder();
  }
}

class _ScheduleLine extends StatelessWidget {
  const _ScheduleLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.canEdit,
    required this.isLoading,
    required this.otherFieldBusy,
    required this.onEditPressed,
    this.editTooltip,
    this.editIcon = Icons.edit_outlined,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool canEdit;
  final bool isLoading;
  final bool otherFieldBusy;
  final VoidCallback onEditPressed;
  final String? editTooltip;
  final IconData editIcon;

  @override
  Widget build(BuildContext context) {
    final isUnset = value == 'Not set';
    final canTap = canEdit && !isLoading && !otherFieldBusy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(AppColors.primaryColor)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isUnset
                      ? const Color(AppColors.textSecondaryColor)
                      : const Color(AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
        if (canEdit)
          IconButton(
            onPressed: canTap ? onEditPressed : null,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(editIcon, size: 22),
            tooltip: isLoading
                ? 'Saving…'
                : (otherFieldBusy ? 'Please wait' : editTooltip),
            color: canTap
                ? const Color(AppColors.primaryColor)
                : const Color(AppColors.textSecondaryColor),
            style: IconButton.styleFrom(
              backgroundColor: const Color(
                AppColors.primaryColor,
              ).withValues(alpha: canTap && !isLoading ? 0.08 : 0.04),
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(AppColors.textColor),
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(AppColors.primaryColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(DateTime d) {
  final local = d.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
