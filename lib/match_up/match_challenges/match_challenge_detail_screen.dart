import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/challenges/challenge_messages_placeholder.dart';
import '../../components/challenges/praposals/propose_time_slot_sheet.dart';
import '../../components/challenges/praposals/propose_turf_sheet.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../turf/model/turf_model.dart';
import '../../turf/turf_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

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
  bool _isSubmittingTimeProposal = false;
  bool _isSubmittingTurfProposal = false;
  List<TurfModel> _myTurfs = const [];

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

  bool get _isSlotAccepted => _match.proposedSlots.any(
    (slot) => slot.status == MatchProposalStatus.accepted,
  );

  bool get _isTurfAccepted => _match.proposedTurfs.any(
    (turf) => turf.status == MatchProposalStatus.accepted,
  );

  String get _myTeamId => widget.isIncoming
      ? (_match.toTeamHelper.getId() ?? '')
      : (_match.fromTeamHelper.getId() ?? '');

  Future<void> _proposeTimeSlot() async {
    if (_isSlotAccepted || _isSubmittingTimeProposal) return;
    if (_match.id == null || _match.id!.isEmpty || _myTeamId.isEmpty) return;

    final selectedSlot = await showModalBottomSheet<ProposeScheduleTimeSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposeTimeSlotSheet(),
    );
    if (selectedSlot == null) return;

    setState(() => _isSubmittingTimeProposal = true);
    final updatedMatch = await _matchmakingService.proposeSchedule(
      _match.id!,
      ProposeScheduleRequest(
        actorTeamId: _myTeamId,
        proposedSlots: [selectedSlot],
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmittingTimeProposal = false);

    if (updatedMatch == null) {
      AppSnackbar.error(
        title: 'Proposal Failed',
        message: 'Could not propose the time slot. Please try again.',
      );
      return;
    }

    setState(() => _match = updatedMatch);
    AppSnackbar.success(
      title: 'Proposal Sent',
      message: 'Time slot proposal has been shared.',
    );
  }

  Future<void> _proposeTurf() async {
    if (_isTurfAccepted || _isSubmittingTurfProposal) return;
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
        title: 'No Turfs Found',
        message: 'Create a turf first before proposing.',
      );
      return;
    }

    final selectedTurfId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProposeTurfSheet(turfs: _myTurfs),
    );
    if (selectedTurfId == null || selectedTurfId.isEmpty) return;

    setState(() => _isSubmittingTurfProposal = true);
    final updatedMatch = await _matchmakingService.proposeSchedule(
      _match.id!,
      ProposeScheduleRequest(
        actorTeamId: _myTeamId,
        proposedTurfIds: [selectedTurfId],
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmittingTurfProposal = false);

    if (updatedMatch == null) {
      AppSnackbar.error(
        title: 'Proposal Failed',
        message: 'Could not propose the turf. Please try again.',
      );
      return;
    }

    setState(() => _match = updatedMatch);
    AppSnackbar.success(
      title: 'Proposal Sent',
      message: 'Turf proposal has been shared.',
    );
  }

  void _decideSlot(String proposalId, ProposalDecisionAction action) {
    setState(() {
      _match = TeamMatchModel(
        id: _match.id,
        source: _match.source,
        fromTeam: _match.fromTeam,
        toTeam: _match.toTeam,
        sportType: _match.sportType,
        status: _match.status,
        statusUpdatedBy: _match.statusUpdatedBy,
        statusUpdatedAt: _match.statusUpdatedAt,
        proposedSlots: _match.proposedSlots.map((slot) {
          if (slot.proposalId != proposalId) return slot;
          return ProposedSlotModel(
            proposalId: slot.proposalId,
            slot: slot.slot,
            proposedByTeamId: slot.proposedByTeamId,
            status: action == ProposalDecisionAction.accept
                ? MatchProposalStatus.accepted
                : MatchProposalStatus.rejected,
            decidedByTeamId: _myTeamId,
            decidedAt: DateTime.now(),
            reason: slot.reason,
            createdAt: slot.createdAt,
            updatedAt: DateTime.now(),
          );
        }).toList(),
        proposedTurfs: _match.proposedTurfs,
        selectedSlotProposalId: action == ProposalDecisionAction.accept
            ? proposalId
            : _match.selectedSlotProposalId,
        selectedTurfProposalId: _match.selectedTurfProposalId,
        winnerTeam: _match.winnerTeam,
        notes: _match.notes,
        expiresAt: _match.expiresAt,
        closedAt: _match.closedAt,
        createdAt: _match.createdAt,
        updatedAt: _match.updatedAt,
      );
    });
  }

  void _decideTurf(String proposalId, ProposalDecisionAction action) {
    setState(() {
      _match = TeamMatchModel(
        id: _match.id,
        source: _match.source,
        fromTeam: _match.fromTeam,
        toTeam: _match.toTeam,
        sportType: _match.sportType,
        status: _match.status,
        statusUpdatedBy: _match.statusUpdatedBy,
        statusUpdatedAt: _match.statusUpdatedAt,
        proposedSlots: _match.proposedSlots,
        proposedTurfs: _match.proposedTurfs.map((turf) {
          if (turf.proposalId != proposalId) return turf;
          return ProposedTurfModel(
            proposalId: turf.proposalId,
            turfId: turf.turfId,
            proposedByTeamId: turf.proposedByTeamId,
            status: action == ProposalDecisionAction.accept
                ? MatchProposalStatus.accepted
                : MatchProposalStatus.rejected,
            decidedByTeamId: _myTeamId,
            decidedAt: DateTime.now(),
            reason: turf.reason,
            createdAt: turf.createdAt,
            updatedAt: DateTime.now(),
          );
        }).toList(),
        selectedSlotProposalId: _match.selectedSlotProposalId,
        selectedTurfProposalId: action == ProposalDecisionAction.accept
            ? proposalId
            : _match.selectedTurfProposalId,
        winnerTeam: _match.winnerTeam,
        notes: _match.notes,
        expiresAt: _match.expiresAt,
        closedAt: _match.closedAt,
        createdAt: _match.createdAt,
        updatedAt: _match.updatedAt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Challenge Details'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppColors.primaryColor),
          labelColor: const Color(AppColors.primaryColor),
          unselectedLabelColor: const Color(AppColors.textSecondaryColor),
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDetailsTab(), _buildMessagesTab()],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final fromTeam = _match.fromTeamHelper.getDisplayName();
    final toTeam = _match.toTeamHelper.getDisplayName();
    final fromTeamId = _match.fromTeamHelper.getId();
    final toTeamId = _match.toTeamHelper.getId();
    final fromLogo = _match.fromTeamHelper.getSubsetModel()?.logo;
    final toLogo = _match.toTeamHelper.getSubsetModel()?.logo;
    final acceptedSlot = _match.proposedSlots.where((slot) {
      if (_match.selectedSlotProposalId != null) {
        return slot.proposalId == _match.selectedSlotProposalId;
      }
      return slot.status == MatchProposalStatus.accepted;
    }).firstOrNull;
    final acceptedTurf = _match.proposedTurfs.where((turf) {
      if (_match.selectedTurfProposalId != null) {
        return turf.proposalId == _match.selectedTurfProposalId;
      }
      return turf.status == MatchProposalStatus.accepted;
    }).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            _InfoCard(
              title: '',
              child: Row(
                children: [
                  Expanded(
                    child: _TeamHeader(
                      teamName: fromTeam,
                      logoUrl: fromLogo,
                      teamId: fromTeamId,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        AppColors.primaryColor,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Color(AppColors.primaryColor),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TeamHeader(
                      teamName: toTeam,
                      logoUrl: toLogo,
                      teamId: toTeamId,
                    ),
                  ),
                ],
              ),
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
                  if (acceptedSlot != null)
                    _InfoTile(
                      icon: Icons.schedule,
                      label: 'Accepted time slot',
                      value:
                          '${_fmt(acceptedSlot.slot.startTime)} - ${_fmt(acceptedSlot.slot.endTime)}',
                    ),
                  if (acceptedTurf != null)
                    _InfoTile(
                      icon: Icons.grass,
                      label: 'Accepted turf',
                      value: acceptedTurf.turfIdHelper.getDisplayName(),
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

        // const SizedBox(height: 12),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Proposed Time Slots',
          child: _match.proposedSlots.isEmpty
              ? const Text(
                  'No proposed time slots yet.',
                  style: TextStyle(color: Color(AppColors.textSecondaryColor)),
                )
              : Column(
                  children: _match.proposedSlots.map((slot) {
                    final canDecide =
                        slot.status == MatchProposalStatus.pending;
                    return _ProposalTile(
                      title:
                          '${_fmt(slot.slot.startTime)} - ${_fmt(slot.slot.endTime)}',
                      subtitle:
                          'By ${slot.proposedByTeamId == _myTeamId ? 'You' : 'Opponent'}',
                      status: slot.status.name,
                      onAccept: canDecide
                          ? () => _decideSlot(
                              slot.proposalId,
                              ProposalDecisionAction.accept,
                            )
                          : null,
                      onReject: canDecide
                          ? () => _decideSlot(
                              slot.proposalId,
                              ProposalDecisionAction.reject,
                            )
                          : null,
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Proposed Turfs',
          child: _match.proposedTurfs.isEmpty
              ? const Text(
                  'No proposed turfs yet.',
                  style: TextStyle(color: Color(AppColors.textSecondaryColor)),
                )
              : Column(
                  children: _match.proposedTurfs.map((turf) {
                    final canDecide =
                        turf.status == MatchProposalStatus.pending;
                    return _ProposalTile(
                      title: turf.turfIdHelper.getDisplayName(),
                      subtitle:
                          'By ${turf.proposedByTeamId == _myTeamId ? 'You' : 'Opponent'}',
                      status: turf.status.name,
                      onAccept: canDecide
                          ? () => _decideTurf(
                              turf.proposalId,
                              ProposalDecisionAction.accept,
                            )
                          : null,
                      onReject: canDecide
                          ? () => _decideTurf(
                              turf.proposalId,
                              ProposalDecisionAction.reject,
                            )
                          : null,
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: '',
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSlotAccepted || _isSubmittingTimeProposal
                      ? null
                      : _proposeTimeSlot,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    _isSlotAccepted
                        ? 'Time Fixed'
                        : _isSubmittingTimeProposal
                        ? 'Sending...'
                        : 'Propose Time',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTurfAccepted || _isSubmittingTurfProposal
                      ? null
                      : _proposeTurf,
                  icon: const Icon(Icons.grass),
                  label: Text(
                    _isTurfAccepted
                        ? 'Turf Fixed'
                        : _isSubmittingTurfProposal
                        ? 'Sending...'
                        : 'Propose Turf',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesTab() {
    return const ChallengeMessagesPlaceholder();
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

class _ProposalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ProposalTile({
    required this.title,
    required this.subtitle,
    required this.status,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final readableStatus = status.capitalizeFirst ?? status;
    final canDecide = onAccept != null || onReject != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  readableStatus,
                  style: const TextStyle(
                    color: Color(AppColors.primaryColor),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (canDecide) ...[
                TextButton(onPressed: onReject, child: const Text('Reject')),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: onAccept,
                  // Theme uses full-width minimumSize; Row must not get infinite width.
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  final String teamName;
  final String? logoUrl;
  final String? teamId;

  const _TeamHeader({required this.teamName, this.logoUrl, this.teamId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: teamId == null || teamId!.isEmpty
          ? null
          : () => Get.toNamed(
              AppConstants.routes.teamProfile,
              arguments: {'teamId': teamId},
            ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(
              AppColors.primaryColor,
            ).withValues(alpha: 0.12),
            backgroundImage: logoUrl != null && logoUrl!.isNotEmpty
                ? NetworkImage(logoUrl!)
                : null,
            child: logoUrl == null || logoUrl!.isEmpty
                ? const Icon(
                    Icons.groups_2_rounded,
                    color: Color(AppColors.primaryColor),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
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
