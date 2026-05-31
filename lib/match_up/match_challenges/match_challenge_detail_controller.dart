import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/challenges/praposals/propose_time_slot_sheet.dart';
import '../../components/challenges/praposals/propose_turf_sheet.dart';
import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/model/team_model.dart';
import '../../team/utils/team_ui.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import 'match_challenges_controller.dart';

class MatchChallengeDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  MatchChallengeDetailController({
    required TeamMatchModel initialMatch,
    required this.isIncoming,
  }) : match = initialMatch.obs;

  final bool isIncoming;
  final Rx<TeamMatchModel> match;

  final MatchmakingService _matchmakingService = MatchmakingService();

  late final TabController detailTabController;

  final RxBool isUpdatingSlot = false.obs;
  final RxBool isUpdatingTurf = false.obs;
  final RxBool isRejectingChallenge = false.obs;
  final RxBool isAcceptingChallenge = false.obs;
  final RxBool actionsChildBusy = false.obs;

  bool get actionBusy =>
      isUpdatingSlot.value ||
      isUpdatingTurf.value ||
      isRejectingChallenge.value ||
      isAcceptingChallenge.value ||
      actionsChildBusy.value;

  bool get canEditSchedule {
    return switch (match.value.status) {
      TeamMatchStatus.requested => true,
      TeamMatchStatus.accepted => true,
      TeamMatchStatus.negotiating => true,
      TeamMatchStatus.scheduleFinalized => true,
      _ => false,
    };
  }

  String get myTeamId => isIncoming
      ? (match.value.toTeamHelper.getId() ?? '')
      : (match.value.fromTeamHelper.getId() ?? '');

  bool get isExpiredByDeadline {
    final expiresAt = match.value.expiresAt;
    return expiresAt != null && DateTime.now().isAfter(expiresAt.toLocal());
  }

  bool get canRespondToChallenge {
    return isIncoming &&
        match.value.status == TeamMatchStatus.requested &&
        !isExpiredByDeadline;
  }

  bool get isCricketMatch => match.value.sportType == TeamSportType.cricket;

  bool get isFootballMatch => match.value.sportType == TeamSportType.football;

  bool get canStartScoring {
    if (!isCricketMatch && !isFootballMatch) return false;
    return match.value.status == TeamMatchStatus.accepted ||
        match.value.status == TeamMatchStatus.scheduleFinalized;
  }

  bool get canUseScheduleControls => canEditSchedule && !actionsChildBusy.value;

  @override
  void onInit() {
    super.onInit();
    detailTabController = TabController(length: 4, vsync: this);
  }

  @override
  void onClose() {
    detailTabController.dispose();
    super.onClose();
  }

  void scheduleMatchUpdate(TeamMatchModel updated) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      match.value = updated;
      _trySyncChallengesList(updated);
    });
  }

  void scheduleActionsChildBusy(bool busy) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (actionsChildBusy.value == busy) return;
      actionsChildBusy.value = busy;
    });
  }

  void _trySyncChallengesList(TeamMatchModel updated) {
    if (!Get.isRegistered<MatchChallengesController>()) return;
    Get.find<MatchChallengesController>().applyMatchUpdateFromDetail(updated);
  }

  Future<void> respondToChallenge(MatchResponseAction action) async {
    if (actionBusy) return;
    if (!canRespondToChallenge) return;
    final matchId = match.value.id;
    if (matchId == null || matchId.isEmpty || myTeamId.isEmpty) return;

    if (action == MatchResponseAction.reject) {
      isRejectingChallenge.value = true;
    } else {
      isAcceptingChallenge.value = true;
    }

    final updated = await _matchmakingService.respond(
      matchId,
      RespondMatchRequest(actorTeamId: myTeamId, action: action),
    );

    isRejectingChallenge.value = false;
    isAcceptingChallenge.value = false;

    if (updated == null) {
      AppSnackbar.error(
        title: action == MatchResponseAction.accept
            ? 'Could not accept'
            : 'Could not reject',
        message: 'Try again later.',
      );
      return;
    }

    match.value = updated;
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

  Future<void> setTimeSlot(BuildContext context) async {
    if (actionBusy) return;
    final matchId = match.value.id;
    if (matchId == null || matchId.isEmpty || myTeamId.isEmpty) return;

    final selected = await showModalBottomSheet<ProposeScheduleTimeSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposeTimeSlotSheet(),
    );
    if (selected == null) return;

    isUpdatingSlot.value = true;
    final updated = await _matchmakingService.updateRequest(
      matchId,
      UpdateTeamMatchRequest(
        slot: TeamMatchTimeSlot(
          startTime: selected.startTime,
          endTime: selected.endTime,
        ),
        selfAcceptTeamId: myTeamId,
      ),
    );
    isUpdatingSlot.value = false;

    if (updated == null) {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'Could not set the time slot. Please try again.',
      );
      return;
    }

    match.value = updated;
    _trySyncChallengesList(updated);
    AppSnackbar.success(
      title: 'Time updated',
      message: 'The match time has been saved.',
    );
  }

  Future<void> setTurf(BuildContext context) async {
    if (actionBusy) return;
    final matchId = match.value.id;
    if (matchId == null || matchId.isEmpty || myTeamId.isEmpty) return;

    final selectedTurfId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => ProposeTurfSheet(
        sportTypes: [teamSportLabel(match.value.sportType)],
      ),
    );
    if (selectedTurfId == null || selectedTurfId.isEmpty) return;

    isUpdatingTurf.value = true;
    final updated = await _matchmakingService.updateRequest(
      matchId,
      UpdateTeamMatchRequest(
        turfId: selectedTurfId,
        selfAcceptTeamId: myTeamId,
      ),
    );
    isUpdatingTurf.value = false;

    if (updated == null) {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'Could not set the turf. Please try again.',
      );
      return;
    }

    match.value = updated;
    _trySyncChallengesList(updated);
    AppSnackbar.success(
      title: 'Turf updated',
      message: 'The venue has been saved.',
    );
  }

  void openScoreboard() {
    final matchId = match.value.id;
    if (matchId == null || matchId.isEmpty) {
      AppSnackbar.error(
        title: 'Missing match id',
        message: 'Unable to open scoreboard for this challenge.',
      );
      return;
    }
    final route = isFootballMatch
        ? AppConstants.routes.footballScoreBoard
        : AppConstants.routes.cricketScoreBoard;
    Get.toNamed(route, arguments: {'matchId': matchId});
  }

  void openMessages() {
    Get.toNamed(
      AppConstants.routes.matchChallengeMessages,
      arguments: {'match': match.value},
    );
  }
}
