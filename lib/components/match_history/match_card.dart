import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../match_up/match_challenges/match_challenge_versus_header.dart';
import '../../match_up/model/team_match_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.selectedTeamId,
    required this.isHistory,

    /// Challenges: personalize Won/Lost and "Your team won".
    /// Public Matches: keep false so the winner team name is shown instead.
    this.personalizeForTeam = false,
    this.onTap,
  });

  final TeamMatchModel match;
  final String? selectedTeamId;
  final bool isHistory;
  final bool personalizeForTeam;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fromTeam = match.fromTeamHelper;
    final toTeam = match.toTeamHelper;
    final fromId = fromTeam.getId();
    final toId = toTeam.getId();
    final fromModel = fromTeam.getSubsetModel();
    final toModel = toTeam.getSubsetModel();

    final hasSide =
        personalizeForTeam &&
        selectedTeamId != null &&
        selectedTeamId!.isNotEmpty &&
        (selectedTeamId == fromId || selectedTeamId == toId);

    final winner = match.winnerTeamHelper;
    final winnerId = winner.getId();

    final statusColor = _statusColor(match.status, winnerId, hasSide);
    final statusLabel = _statusLabel(match.status, winnerId, hasSide);

    final selectedSlot = _getSelectedSlot();
    final fromScore = scoreForTeam(match, fromId);
    final toScore = scoreForTeam(match, toId);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TeamColumn(
                name: fromTeam.getDisplayName(),
                logoUrl: fromModel?.logo ?? '',
                teamId: fromId,
                score: fromScore,
                isWinner: isHistory && winnerId != null && winnerId == fromId,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: Color(AppColors.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _TeamColumn(
                name: toTeam.getDisplayName(),
                logoUrl: toModel?.logo ?? '',
                teamId: toId,
                score: toScore,
                isWinner: isHistory && winnerId != null && winnerId == toId,
              ),
            ),
          ],
        ),
        if (selectedSlot != null) ...[
          const SizedBox(height: 10),
          Text(
            _formatSlot(selectedSlot),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
        ],
        if (hasSide && isHistory && winnerId != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasSide && winnerId == selectedTeamId
                    ? Icons.emoji_events
                    : Icons.emoji_events_outlined,
                size: 16,
                color: hasSide && winnerId == selectedTeamId
                    ? const Color(0xFFF59E0B)
                    : const Color(AppColors.primaryColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasSide
                      ? (winnerId == selectedTeamId
                            ? 'Your team won!'
                            : 'Opponent won')
                      : '${winner.getDisplayName()} won',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasSide && winnerId == selectedTeamId
                        ? const Color(0xFFF59E0B)
                        : const Color(AppColors.textColor),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (isHistory && match.status == TeamMatchStatus.draw) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 16,
                color: Color(AppColors.textSecondaryColor),
              ),
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
      child: Padding(padding: const EdgeInsets.all(14), child: content),
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

  Color _statusColor(TeamMatchStatus status, String? winnerId, bool hasSide) {
    switch (status) {
      case TeamMatchStatus.completed:
        if (!hasSide) return const Color(AppColors.primaryColor);
        if (winnerId == selectedTeamId) return const Color(0xFF10B981);
        return const Color(0xFFEF4444);
      case TeamMatchStatus.draw:
        return const Color(0xFFF59E0B);
      case TeamMatchStatus.scheduleFinalized:
        return const Color(AppColors.primaryColor);
      case TeamMatchStatus.ongoing:
        return const Color(0xFFEF4444);
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

  String _statusLabel(TeamMatchStatus status, String? winnerId, bool hasSide) {
    switch (status) {
      case TeamMatchStatus.completed:
        if (!hasSide) return 'Completed';
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
        return 'Live';
      case TeamMatchStatus.abandoned:
        return 'Abandoned';
    }
  }

  String _formatSlot(TeamMatchTimeSlot slot) {
    final dateFmt = DateFormat('MMM dd');
    final timeFmt = DateFormat('hh:mm a');
    final start = slot.startTime.toLocal();
    final end = slot.endTime.toLocal();
    return '${dateFmt.format(start)} — ${timeFmt.format(start)} to ${timeFmt.format(end)}';
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.name,
    required this.logoUrl,
    required this.teamId,
    this.score,
    this.isWinner = false,
  });

  final String name;
  final String logoUrl;
  final String? teamId;
  final MatchTeamScoreLine? score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              TeamLogo(url: logoUrl, size: 44, teamId: teamId),
              if (isWinner)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFFB300),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 11,
                            color: Color(0xFF5D4200),
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Won',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5D4200),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.textColor),
          ),
        ),
        if (score != null) ...[
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: score!.main,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.primaryColor),
                    height: 1.1,
                  ),
                ),
                if (score!.overs != null)
                  TextSpan(
                    text: ' ${score!.overs}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(AppColors.textSecondaryColor),
                      height: 1.1,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
