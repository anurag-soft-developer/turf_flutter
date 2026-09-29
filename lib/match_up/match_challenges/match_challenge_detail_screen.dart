import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/announced_players/manage_announced_players_sheet.dart';
import '../../components/announced_players/match_announced_players_section.dart';
import '../../components/scoring/cricket/scorecard/match_scorecard_tab.dart';
import '../../components/challenges/match_challenge_respond_actions.dart';
import '../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/models/location_model.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/map_launch_util.dart';
import '../../explore/model/content_post_model.dart';
import '../../explore/post_service.dart';
import '../../explore/widgets/tagged_posts_grid.dart';
import '../../match_up/guest_join/guest_join_service.dart';
import '../model/team_match_model.dart';
import 'match_challenge_detail_controller.dart';
import 'match_challenge_versus_header.dart';
import 'match_challenges_controller.dart';

Future<T?>? openMatchChallengeDetail<T>({
  TeamMatchModel? match,
  String? matchId,
  bool? isIncoming,
}) {
  final id = (matchId ?? match?.id)?.trim();
  assert(id != null && id.isNotEmpty, 'Provide match or matchId');
  if (id == null || id.isEmpty) return null;

  return Get.toNamed<T>(
    AppConstants.routes.matchChallengeDetail(id),
    arguments: {
      'matchId': id,
      if (isIncoming != null) 'isIncoming': isIncoming,
    },
    preventDuplicates: false,
  );
}

PopupMenuItem<String> _guestJoinMenuItem({
  required String value,
  required String teamName,
  required bool isOpen,
}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(
          isOpen ? Icons.group_off_outlined : Icons.group_add_outlined,
          size: 20,
          color: const Color(AppColors.textColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${isOpen ? 'Close' : 'Allow'} guest joining · $teamName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(AppColors.textColor)),
          ),
        ),
      ],
    ),
  );
}

Future<void> _toggleGuestJoin(
  MatchChallengeDetailController controller, {
  required String teamId,
  required String teamName,
  required bool open,
}) async {
  if (controller.isUpdatingGuestJoin.value) return;
  controller.isUpdatingGuestJoin.value = true;
  try {
    final status = await GuestJoinService().updateSettings(
      matchId: controller.matchId,
      actorTeamId: teamId,
      open: !open,
    );
    if (status == null) {
      throw StateError('Guest-join settings were not returned.');
    }
    await controller.loadMatchQuiet();
    if (Get.isRegistered<QueryClient>()) {
      await Get.find<QueryClient>().invalidateQueries(
        queryKey: QueryKeys.explorePrefix,
      );
    }
    AppSnackbar.success(
      title: 'Guest joining updated',
      message: '${open ? 'Closed' : 'Opened'} for $teamName.',
    );
  } catch (error) {
    AppSnackbar.error(
      title: 'Could not update guest joining',
      message: '$error',
    );
  } finally {
    controller.isUpdatingGuestJoin.value = false;
  }
}

class MatchChallengeDetailScreen extends StatelessWidget {
  const MatchChallengeDetailScreen({super.key, required this.matchId});

  /// Fixed at route factory time so rebuilds after scoreboard pop keep the id.
  final String matchId;

  MatchChallengeDetailController get controller =>
      Get.find<MatchChallengeDetailController>(tag: matchId);

  @override
  Widget build(BuildContext context) {
    if (matchId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(AppColors.backgroundColor),
        appBar: AppAppBar(title: const Text('Challenge Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Challenge not found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final c = controller;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(
        title: Obx(() {
          final unranked = c.match.value?.isUnranked == true;
          return Text(unranked ? 'Unranked match' : 'Challenge Details');
        }),
        actions: [
          Obx(() {
            final match = c.match.value;
            if (match == null) return const SizedBox.shrink();

            final fromTeamId = match.fromTeamHelper.getId() ?? '';
            final toTeamId = match.toTeamHelper.getId() ?? '';
            final guestSettingsEditable =
                match.isUnranked &&
                match.cricketState == null &&
                match.footballState == null &&
                MatchAnnouncedPlayersSection.allowsAnnouncedPlayerEdits(match);
            final canManageFrom =
                guestSettingsEditable && c.canManageGuestJoin(fromTeamId);
            final canManageTo =
                guestSettingsEditable && c.canManageGuestJoin(toTeamId);
            c.myMatchTeamIds.value;
            final canRevoke = c.canRevokeMatch;
            final canCancel = c.canCancelOrAbandonMatch;
            if (!canRevoke && !canCancel && !canManageFrom && !canManageTo) {
              return const SizedBox.shrink();
            }
            final abandon = c.isAbandonMatch;
            final busy = c.actionBusy;
            final guestJoin = match.guestJoin;
            return PopupMenuButton<String>(
              tooltip: 'Match actions',
              enabled: !busy,
              icon:
                  busy &&
                      (c.isCancellingMatch.value || c.isUpdatingGuestJoin.value)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'guest_join_from') {
                  await _toggleGuestJoin(
                    c,
                    teamId: fromTeamId,
                    teamName: match.fromTeamHelper.getDisplayName(),
                    open: guestJoin?.fromTeamOpen ?? false,
                  );
                } else if (value == 'guest_join_to') {
                  await _toggleGuestJoin(
                    c,
                    teamId: toTeamId,
                    teamName: match.toTeamHelper.getDisplayName(),
                    open: guestJoin?.toTeamOpen ?? false,
                  );
                } else if (value == 'revoke') {
                  final ok = await c.revokeMatch();
                  if (!ok || !context.mounted) return;
                  // Schedule after this frame so Challenges rebuild isn't
                  // interleaved with reactive tab updates mid-build.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Get.isRegistered<MatchChallengesController>()) {
                      Get.find<MatchChallengesController>().selectedTab.value =
                          MatchChallengesTab.sent;
                    }
                    Get.offNamedUntil(
                      AppConstants.routes.matchUpChallenges,
                      (route) => route.isFirst,
                      arguments: {'tab': 'sent'},
                    );
                  });
                } else if (value == 'cancel_or_abandon') {
                  final reason = await showCancelOrAbandonMatchDialog(
                    context,
                    abandon: abandon,
                  );
                  if (reason == null) return;
                  await c.cancelOrAbandonMatch(
                    reason: reason.isEmpty ? null : reason,
                  );
                }
              },
              itemBuilder: (context) => [
                if (canManageFrom)
                  _guestJoinMenuItem(
                    value: 'guest_join_from',
                    teamName: match.fromTeamHelper.getDisplayName(),
                    isOpen: guestJoin?.fromTeamOpen ?? false,
                  ),
                if (canManageTo)
                  _guestJoinMenuItem(
                    value: 'guest_join_to',
                    teamName: match.toTeamHelper.getDisplayName(),
                    isOpen: guestJoin?.toTeamOpen ?? false,
                  ),
                if (canRevoke)
                  PopupMenuItem<String>(
                    value: 'revoke',
                    child: Row(
                      children: [
                        Icon(
                          Icons.undo_outlined,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Revoke',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                if (canCancel)
                  PopupMenuItem<String>(
                    value: 'cancel_or_abandon',
                    child: Row(
                      children: [
                        Icon(
                          abandon
                              ? Icons.dangerous_outlined
                              : Icons.cancel_outlined,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          abandon ? 'Abandon' : 'Cancel',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Messages',
            onPressed: c.openMessages,
          ),
        ],
      ),
      body: Obx(() {
        if (c.isBootstrapping.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryColor),
              ),
            ),
          );
        }

        final err = c.loadError.value;
        final currentMatch = c.match.value;
        if (currentMatch == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (err != null && err.isNotEmpty)
                        ? err
                        : 'Could not load challenge.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: c.reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Touch side flags so Obx rebuilds when incoming/membership context changes.
        c.isIncoming.value;
        c.myMatchTeamIds.value;

        return _MatchChallengeDetailBody(controller: c, match: currentMatch);
      }),
    );
  }
}

class _MatchChallengeDetailBody extends StatelessWidget {
  const _MatchChallengeDetailBody({
    required this.controller,
    required this.match,
  });

  final MatchChallengeDetailController controller;
  final TeamMatchModel match;

  @override
  Widget build(BuildContext context) {
    final currentMatch = match;
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

    final venueLocation = currentMatch.venueLocation;
    final venueAddress = venueLocation?.address.trim();
    final hasVenueLocation =
        venueAddress != null && venueAddress.isNotEmpty;
    final timeSummary = acceptedSlot != null
        ? '${_fmt(acceptedSlot.slot.startTime)} – ${_fmt(acceptedSlot.slot.endTime)}'
        : 'Not set';
    final turfSummary = acceptedTurf != null
        ? acceptedTurf.turfIdHelper.getDisplayName()
        : 'Not set';
    final locationSummary = hasVenueLocation ? venueAddress : 'Not set';

    final showScoreboardBar =
        (controller.isCricketMatch || controller.isFootballMatch) &&
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
                fillWidth: true,
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
                ],
              ),
              Expanded(
                child: AppSegmentedTabView(
                  controller: controller.detailTabController,
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _InfoCard(
                                title: 'Schedule',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Obx(
                                      () => _ScheduleLine(
                                        icon: Icons.schedule,
                                        label: 'Time',
                                        value: timeSummary,
                                        canEdit:
                                            controller.canUseScheduleControls,
                                        isLoading:
                                            controller.isUpdatingSlot.value,
                                        otherFieldBusy:
                                            controller.isUpdatingTurf.value ||
                                            controller
                                                .isUpdatingLocation
                                                .value ||
                                            controller.isCancellingMatch.value,
                                        onEditPressed: () =>
                                            controller.setTimeSlot(context),
                                        editTooltip: 'Edit time',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Obx(
                                      () => _ScheduleLine(
                                        icon: Icons.grass,
                                        label: 'Turf',
                                        value: turfSummary,
                                        canEdit:
                                            controller.canUseScheduleControls,
                                        isLoading:
                                            controller.isUpdatingTurf.value,
                                        otherFieldBusy:
                                            controller.isUpdatingSlot.value ||
                                            controller
                                                .isUpdatingLocation
                                                .value ||
                                            controller.isCancellingMatch.value,
                                        onEditPressed: () =>
                                            controller.setTurf(context),
                                        editTooltip: 'Edit turf',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Obx(
                                      () => _ScheduleLine(
                                        icon: Icons.location_on_outlined,
                                        label: 'Location',
                                        value: locationSummary,
                                        location: hasVenueLocation
                                            ? venueLocation
                                            : null,
                                        showLocationUnderValue: false,
                                        canEdit:
                                            controller.canUseScheduleControls,
                                        isLoading: controller
                                            .isUpdatingLocation
                                            .value,
                                        otherFieldBusy:
                                            controller.isUpdatingSlot.value ||
                                            controller.isUpdatingTurf.value ||
                                            controller.isCancellingMatch.value,
                                        onEditPressed: () =>
                                            controller.setLocation(context),
                                        editTooltip: 'Edit location',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Photos',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(AppColors.textColor),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        if (currentMatch.id != null &&
                            currentMatch.id!.isNotEmpty)
                          TaggedPostsGrid(
                            filter: PostFilterQuery(
                              match: currentMatch.id,
                              status: PostStatus.published,
                              limit: PostService.userPostsPageSize,
                            ),
                          )
                        else
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                      ],
                    ),
                    MatchScorecardTab(
                      match: currentMatch,
                      parentTabController: controller.detailTabController,
                    ),
                    SingleChildScrollView(
                      child: Obx(
                        () => MatchAnnouncedPlayersSection(
                          match: currentMatch,
                          myTeamId: controller.myTeamId,
                          editableTeamIds: controller.editableAnnounceTeamIds,
                          onMatchUpdated: controller.scheduleMatchUpdate,
                        ),
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
                  Obx(() {
                    final ongoing =
                        currentMatch.status == TeamMatchStatus.ongoing;
                    final myTeamId = controller.myTeamId;
                    final fromId = currentMatch.fromTeamHelper.getId() ?? '';
                    final toId = currentMatch.toTeamHelper.getId() ?? '';
                    final editable = controller.editableAnnounceTeamIds;
                    final ready =
                        MatchAnnouncedPlayersSection.bothTeamsHaveAnnouncedPlayers(
                          currentMatch,
                        );
                    final canEdit =
                        MatchAnnouncedPlayersSection.allowsAnnouncedPlayerEdits(
                          currentMatch,
                        );

                    String? nextAnnounceTeamId;
                    if (canEdit && !ongoing && !ready) {
                      if (editable.contains(fromId) &&
                          !MatchAnnouncedPlayersSection.teamHasAnnouncedPlayers(
                            currentMatch,
                            fromId,
                          )) {
                        nextAnnounceTeamId = fromId;
                      } else if (editable.contains(toId) &&
                          !MatchAnnouncedPlayersSection.teamHasAnnouncedPlayers(
                            currentMatch,
                            toId,
                          )) {
                        nextAnnounceTeamId = toId;
                      } else if (editable.contains(myTeamId) &&
                          myTeamId.isNotEmpty &&
                          !MatchAnnouncedPlayersSection.teamHasAnnouncedPlayers(
                            currentMatch,
                            myTeamId,
                          )) {
                        nextAnnounceTeamId = myTeamId;
                      }
                    }

                    final showHint = !ongoing && !ready;
                    final minPlayers =
                        MatchAnnouncedPlayersSection.minAnnouncedPlayersPerTeam;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHint)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Minimum $minPlayers players per team required to start',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: controller.actionBusy
                                ? null
                                : () {
                                    if (ongoing || ready) {
                                      controller.openScoreboard();
                                      return;
                                    }
                                    final teamId = nextAnnounceTeamId;
                                    if (teamId != null) {
                                      openManageAnnouncedPlayersSheet(
                                        context: context,
                                        match: currentMatch,
                                        actorTeamId: teamId,
                                        onSaved: controller.scheduleMatchUpdate,
                                      );
                                      return;
                                    }
                                    AppSnackbar.info(
                                      title: 'Squad not ready',
                                      message:
                                          'Waiting for the other team to announce players.',
                                    );
                                  },
                            icon: Icon(
                              ongoing
                                  ? Icons.scoreboard_outlined
                                  : Icons.play_circle_outline,
                            ),
                            label: Text(
                              ongoing ? 'Open scoreboard' : 'Start match',
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
                if (showScoreboardBar && controller.canRespondToChallenge)
                  const SizedBox(height: 12),
                if (controller.canRespondToChallenge)
                  Obx(
                    () => MatchChallengeRespondActions(
                      isRejecting: controller.isRejectingChallenge.value,
                      isAccepting: controller.isAcceptingChallenge.value,
                      enabled:
                          !controller.isUpdatingSlot.value &&
                          !controller.isUpdatingTurf.value &&
                          !controller.isCancellingMatch.value,
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
    if (showScoreboardBar) overlay += 100;
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
    this.location,
    this.showLocationUnderValue = true,
    this.editTooltip,
    this.editIcon = Icons.edit_outlined,
  });

  final IconData icon;
  final String label;
  final String value;
  final LocationModel? location;
  final bool showLocationUnderValue;
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
    final showMapsLink =
        location != null && showLocationUnderValue && !isUnset;

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
              if (location != null && !showLocationUnderValue && !isUnset)
                _CompactTurfLocation(location: location!)
              else
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isUnset
                        ? const Color(AppColors.textSecondaryColor)
                        : const Color(AppColors.textColor),
                  ),
                ),
              if (showMapsLink) ...[
                const SizedBox(height: 4),
                _CompactTurfLocation(location: location!),
              ],
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

class _CompactTurfLocation extends StatelessWidget {
  const _CompactTurfLocation({required this.location});

  final LocationModel location;

  @override
  Widget build(BuildContext context) {
    final canOpenMaps = canOpenLocationInMaps(location);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canOpenMaps ? () => openLocationInMaps(location) : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: canOpenMaps
                    ? const Color(AppColors.primaryColor)
                    : const Color(AppColors.textSecondaryColor),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: canOpenMaps
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.textSecondaryColor),
                    decoration: canOpenMaps
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: const Color(AppColors.primaryColor),
                  ),
                ),
              ),
              if (canOpenMaps) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: Color(AppColors.primaryColor),
                ),
              ],
            ],
          ),
        ),
      ),
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

/// Returns trimmed reason text when confirmed, or `null` when dismissed.
Future<String?> showCancelOrAbandonMatchDialog(
  BuildContext context, {
  required bool abandon,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _CancelOrAbandonMatchDialog(abandon: abandon),
  );
}

class _CancelOrAbandonMatchDialog extends StatefulWidget {
  const _CancelOrAbandonMatchDialog({required this.abandon});

  final bool abandon;

  @override
  State<_CancelOrAbandonMatchDialog> createState() =>
      _CancelOrAbandonMatchDialogState();
}

class _CancelOrAbandonMatchDialogState
    extends State<_CancelOrAbandonMatchDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final abandon = widget.abandon;
    return AlertDialog(
      title: Text(abandon ? 'Abandon this match?' : 'Cancel this match?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            abandon
                ? 'This will abandon the live match for both teams. You can add an optional note below.'
                : 'This will cancel the match for both teams. You can add an optional note below.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
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
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context, _reasonController.text.trim());
          },
          child: Text(
            abandon ? 'Abandon match' : 'Cancel match',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ],
    );
  }
}
