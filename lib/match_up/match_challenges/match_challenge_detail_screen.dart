import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/announced_players/match_announced_players_section.dart';
import '../../components/scoring/cricket/scorecard/match_scorecard_tab.dart';
import '../../components/challenges/match_challenge_respond_actions.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/config/constants.dart';
import '../model/team_match_model.dart';
import 'match_challenge_actions_card.dart';
import 'match_challenge_detail_controller.dart';
import 'match_challenge_versus_header.dart';

Future<T?>? openMatchChallengeDetail<T>({
  required TeamMatchModel match,
  required bool isIncoming,
}) {
  return Get.to<T>(
    () => const MatchChallengeDetailScreen(),
    binding: BindingsBuilder(
      () => Get.lazyPut(
        () => MatchChallengeDetailController(
          initialMatch: match,
          isIncoming: isIncoming,
        ),
      ),
    ),
  );
}

class MatchChallengeDetailScreen extends GetView<MatchChallengeDetailController> {
  const MatchChallengeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Challenge Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Messages',
            onPressed: controller.openMessages,
          ),
        ],
      ),
      body: Obx(() => _buildDetailsBody(context)),
    );
  }

  Widget _buildDetailsBody(BuildContext context) {
    final currentMatch = controller.match.value;
    final acceptedSlotCandidates = currentMatch.proposedSlots.where((slot) {
      if (currentMatch.selectedSlotProposalId != null) {
        return slot.proposalId == currentMatch.selectedSlotProposalId;
      }
      return slot.status == MatchProposalStatus.accepted;
    });
    final acceptedSlot = acceptedSlotCandidates.isEmpty
        ? null
        : acceptedSlotCandidates.first;
    final acceptedTurfCandidates = currentMatch.proposedTurfs.where((turf) {
      if (currentMatch.selectedTurfProposalId != null) {
        return turf.proposalId == currentMatch.selectedTurfProposalId;
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

    final showScoreboardBar = (controller.isCricketMatch ||
            controller.isFootballMatch) &&
        (controller.canStartScoring ||
            currentMatch.status == TeamMatchStatus.ongoing);
    final showFloatingBottom =
        showScoreboardBar || controller.canRespondToChallenge;

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            _mainContentBottomPadding(showScoreboardBar),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              _InfoCard(
                title: '',
                child: MatchChallengeVersusHeader(match: currentMatch),
              ),
              const SizedBox(height: 16),
              AppSegmentedTabs(
                controller: controller.detailTabController,
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                items: const [
                  AppTabItem(
                    label: 'Details',
                    icon: Icons.info_outline_rounded,
                  ),
                  AppTabItem(
                    label: 'Scorecard',
                    icon: Icons.scoreboard_outlined,
                  ),
                  AppTabItem(label: 'Players', icon: Icons.groups_outlined),
                  AppTabItem(label: 'Actions', icon: Icons.bolt_outlined),
                ],
              ),
              Expanded(
                child: AppSegmentedTabView(
                  controller: controller.detailTabController,
                  children: [
                    SingleChildScrollView(
                      child: _InfoCard(
                        title: 'Schedule',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Obx(
                              () => _ScheduleLine(
                                icon: Icons.schedule,
                                label: 'Time',
                                value: timeSummary,
                                canEdit: controller.canUseScheduleControls,
                                isLoading: controller.isUpdatingSlot.value,
                                otherFieldBusy: controller.isUpdatingTurf.value ||
                                    controller.actionsChildBusy.value,
                                onEditPressed: () =>
                                    controller.setTimeSlot(context),
                                editTooltip: hasSlot ? 'Edit time' : 'Set time',
                                editIcon: hasSlot
                                    ? Icons.edit_outlined
                                    : Icons.event_available_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => _ScheduleLine(
                                icon: Icons.grass,
                                label: 'Turf',
                                value: turfSummary,
                                canEdit: controller.canUseScheduleControls,
                                isLoading: controller.isUpdatingTurf.value,
                                otherFieldBusy: controller.isUpdatingSlot.value ||
                                    controller.actionsChildBusy.value,
                                onEditPressed: () =>
                                    controller.setTurf(context),
                                editTooltip: hasTurf ? 'Edit turf' : 'Set turf',
                                editIcon: hasTurf
                                    ? Icons.edit_outlined
                                    : Icons.add_location_alt_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    MatchScorecardTab(
                      match: currentMatch,
                      parentTabController: controller.detailTabController,
                    ),
                    SingleChildScrollView(
                      child: MatchAnnouncedPlayersSection(
                        match: currentMatch,
                        myTeamId: controller.myTeamId,
                        onMatchUpdated: controller.scheduleMatchUpdate,
                      ),
                    ),
                    SingleChildScrollView(
                      child: MatchChallengeActionsCard(
                        match: currentMatch,
                        myTeamId: controller.myTeamId,
                        onMatchUpdated: controller.scheduleMatchUpdate,
                        onInternalBusyChanged: controller.scheduleActionsChildBusy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showFloatingBottom)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showScoreboardBar) ...[
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.actionBusy
                            ? null
                            : controller.openScoreboard,
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Scoreboard'),
                      ),
                    ),
                  ),
                ],
                if (showScoreboardBar && controller.canRespondToChallenge)
                  const SizedBox(height: 12),
                if (controller.canRespondToChallenge)
                  Obx(
                    () => MatchChallengeRespondActions(
                      isRejecting: controller.isRejectingChallenge.value,
                      isAccepting: controller.isAcceptingChallenge.value,
                      enabled: !controller.isUpdatingSlot.value &&
                          !controller.isUpdatingTurf.value &&
                          !controller.actionsChildBusy.value,
                      onReject: () => controller.respondToChallenge(
                        MatchResponseAction.reject,
                      ),
                      onAccept: () => controller.respondToChallenge(
                        MatchResponseAction.accept,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  double _mainContentBottomPadding(bool showScoreboardBar) {
    const base = 16.0;
    if (!showScoreboardBar && !controller.canRespondToChallenge) return base;
    double overlay = 0;
    if (showScoreboardBar) overlay += 76;
    if (showScoreboardBar && controller.canRespondToChallenge) overlay += 12;
    if (controller.canRespondToChallenge) overlay += 56;
    return base + overlay;
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

String _fmt(DateTime d) {
  final local = d.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
