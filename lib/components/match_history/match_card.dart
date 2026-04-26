import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../match_up/model/team_match_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.selectedTeamId,
    required this.isHistory,
    this.onTap,
  });

  final TeamMatchModel match;
  final String? selectedTeamId;
  final bool isHistory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fromTeam = match.fromTeamHelper;
    final toTeam = match.toTeamHelper;

    final isFromTeamMine = fromTeam.getId() == selectedTeamId;
    final opponent = isFromTeamMine ? toTeam : fromTeam;
    final opponentModel = opponent.getSubsetModel();

    final winner = match.winnerTeamHelper;
    final winnerId = winner.getId();

    final statusColor = _statusColor(match.status, winnerId);
    final statusLabel = _statusLabel(match.status, winnerId);

    final dateStr = _formatDate(
      isHistory ? (match.updatedAt ?? match.createdAt) : match.createdAt,
    );

    final selectedSlot = _getSelectedSlot();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
            Row(
              children: [
                TeamLogo(
                  url: opponentModel?.logo ?? '',
                  size: 44,
                  teamId: opponent.getId(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs ${opponent.getDisplayName()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (selectedSlot != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(AppColors.backgroundColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 16,
                        color: Color(AppColors.textSecondaryColor)),
                    const SizedBox(width: 8),
                    Text(
                      _formatSlot(selectedSlot),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isHistory && winnerId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    winnerId == selectedTeamId
                        ? Icons.emoji_events
                        : Icons.sports_score,
                    size: 16,
                    color: winnerId == selectedTeamId
                        ? const Color(0xFFF59E0B)
                        : const Color(AppColors.textSecondaryColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    winnerId == selectedTeamId
                        ? 'Your team won!'
                        : 'Opponent won',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: winnerId == selectedTeamId
                          ? const Color(0xFFF59E0B)
                          : const Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ],
            if (isHistory && match.status == TeamMatchStatus.draw) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 16,
                      color: Color(AppColors.textSecondaryColor)),
                  SizedBox(width: 6),
                  Text(
                    'Match ended in a draw',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ],
      ],
    );

    final body = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: content,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: body,
              ),
            ),
    );
  }

  TeamMatchTimeSlot? _getSelectedSlot() {
    if (match.selectedSlotProposalId == null) return null;
    for (final s in match.proposedSlots) {
      if (s.proposalId == match.selectedSlotProposalId) {
        return s.slot;
      }
    }
    return null;
  }

  Color _statusColor(TeamMatchStatus status, String? winnerId) {
    switch (status) {
      case TeamMatchStatus.completed:
        if (winnerId == selectedTeamId) return const Color(0xFF10B981);
        return const Color(0xFFEF4444);
      case TeamMatchStatus.draw:
        return const Color(0xFFF59E0B);
      case TeamMatchStatus.scheduleFinalized:
        return const Color(AppColors.primaryColor);
      case TeamMatchStatus.accepted:
      case TeamMatchStatus.negotiating:
        return const Color(0xFF3B82F6);
      case TeamMatchStatus.cancelled:
      case TeamMatchStatus.rejected:
      case TeamMatchStatus.expired:
        return const Color(AppColors.textSecondaryColor);
      default:
        return const Color(AppColors.textSecondaryColor);
    }
  }

  String _statusLabel(TeamMatchStatus status, String? winnerId) {
    switch (status) {
      case TeamMatchStatus.completed:
        if (winnerId == selectedTeamId) return 'Won';
        return 'Lost';
      case TeamMatchStatus.draw:
        return 'Draw';
      case TeamMatchStatus.scheduleFinalized:
        return 'Scheduled';
      case TeamMatchStatus.accepted:
        return 'Accepted';
      case TeamMatchStatus.negotiating:
        return 'Negotiating';
      case TeamMatchStatus.requested:
        return 'Pending';
      case TeamMatchStatus.cancelled:
        return 'Cancelled';
      case TeamMatchStatus.rejected:
        return 'Rejected';
      case TeamMatchStatus.expired:
        return 'Expired';
      case TeamMatchStatus.ongoing:
        return 'Ongoing';
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  String _formatSlot(TeamMatchTimeSlot slot) {
    final dateFmt = DateFormat('MMM dd');
    final timeFmt = DateFormat('hh:mm a');
    final start = slot.startTime.toLocal();
    final end = slot.endTime.toLocal();
    return '${dateFmt.format(start)} — ${timeFmt.format(start)} to ${timeFmt.format(end)}';
  }
}
