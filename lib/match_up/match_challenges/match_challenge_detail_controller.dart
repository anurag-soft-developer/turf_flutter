import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/challenges/praposals/propose_time_slot_sheet.dart';
import '../../components/challenges/praposals/propose_turf_sheet.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/utils/team_ui.dart';
import '../../team/model/team_model.dart' show TeamSportType;
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

/// Tab + mutation state for challenge detail. Match data is owned by flutter_query.
class MatchChallengeDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  MatchChallengeDetailController({
    this.initialMatch,
    this.matchIdArg,
    this.explicitIsIncoming,
  });

  final TeamMatchModel? initialMatch;
  final String? matchIdArg;
  final bool? explicitIsIncoming;

  final Rxn<TeamMatchModel> match = Rxn<TeamMatchModel>();
  final RxBool isIncoming = false.obs;

  final MatchmakingService _matchmakingService = MatchmakingService();

  late final TabController detailTabController;

  final RxBool isUpdatingSlot = false.obs;
  final RxBool isUpdatingTurf = false.obs;
  final RxBool isRejectingChallenge = false.obs;
  final RxBool isAcceptingChallenge = false.obs;
  final RxBool actionsChildBusy = false.obs;

  String? get resolvedMatchId {
    final fromMatch = match.value?.id ?? initialMatch?.id;
    if (fromMatch != null && fromMatch.isNotEmpty) return fromMatch;
    final arg = matchIdArg?.trim();
    if (arg != null && arg.isNotEmpty) return arg;
    return null;
  }

  bool get actionBusy =>
      isUpdatingSlot.value ||
      isUpdatingTurf.value ||
      isRejectingChallenge.value ||
      isAcceptingChallenge.value ||
      actionsChildBusy.value;

  bool get canEditSchedule {
    final m = match.value;
    if (m == null) return false;
    return switch (m.status) {
      TeamMatchStatus.requested => true,
      TeamMatchStatus.accepted => true,
      TeamMatchStatus.negotiating => true,
      TeamMatchStatus.scheduleFinalized => true,
      _ => false,
    };
  }

  String get myTeamId => isIncoming.value
      ? (match.value?.toTeamHelper.getId() ?? '')
      : (match.value?.fromTeamHelper.getId() ?? '');

  bool get isExpiredByDeadline {
    final expiresAt = match.value?.expiresAt;
    return expiresAt != null && DateTime.now().isAfter(expiresAt.toLocal());
  }

  bool get canRespondToChallenge {
    return isIncoming.value &&
        match.value?.status == TeamMatchStatus.requested &&
        !isExpiredByDeadline;
  }

  bool get isCricketMatch => match.value?.sportType == TeamSportType.cricket;

  bool get isFootballMatch => match.value?.sportType == TeamSportType.football;

  bool get canStartScoring {
    if (!isCricketMatch && !isFootballMatch) return false;
    final status = match.value?.status;
    return status == TeamMatchStatus.accepted ||
        status == TeamMatchStatus.scheduleFinalized;
  }

  bool get canUseScheduleControls => canEditSchedule && !actionsChildBusy.value;

  @override
  void onInit() {
    super.onInit();
    detailTabController = TabController(length: 3, vsync: this);
    if (initialMatch != null) {
      match.value = initialMatch;
    }
    if (explicitIsIncoming != null) {
      isIncoming.value = explicitIsIncoming!;
    }
  }

  @override
  void onClose() {
    detailTabController.dispose();
    super.onClose();
  }

  void syncMatch(TeamMatchModel? value) {
    if (value == null) return;
    match.value = value;
  }

  void syncIsIncoming(bool value) {
    isIncoming.value = value;
  }

  void scheduleMatchUpdate(TeamMatchModel updated) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      match.value = updated;
      _invalidateMatchQueries(updated);
    });
  }

  void scheduleActionsChildBusy(bool busy) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (actionsChildBusy.value == busy) return;
      actionsChildBusy.value = busy;
    });
  }

  Future<void> _invalidateMatchQueries(TeamMatchModel updated) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final id = updated.id;
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: const ['matchChallenges']),
    ];
    if (id != null && id.isNotEmpty) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.matchChallengeDetail(id)),
      );
    }
    await Future.wait(futures);
  }

  Future<void> respondToChallenge(MatchResponseAction action) async {
    if (actionBusy) return;
    if (!canRespondToChallenge) return;
    final matchId = match.value?.id;
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

    if (updated == null) return;

    match.value = updated;
    await _invalidateMatchQueries(updated);
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
    final matchId = match.value?.id;
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

    if (updated == null) return;

    match.value = updated;
    await _invalidateMatchQueries(updated);
    AppSnackbar.success(
      title: 'Time updated',
      message: 'The match time has been saved.',
    );
  }

  Future<void> setTurf(BuildContext context) async {
    if (actionBusy) return;
    final matchId = match.value?.id;
    if (matchId == null || matchId.isEmpty || myTeamId.isEmpty) return;

    final selectedTurfId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => ProposeTurfSheet(
        sportTypes: [teamSportLabel(match.value!.sportType)],
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

    if (updated == null) return;

    match.value = updated;
    await _invalidateMatchQueries(updated);
    AppSnackbar.success(
      title: 'Turf updated',
      message: 'The venue has been saved.',
    );
  }

  void openScoreboard() {
    final matchId = match.value?.id;
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
    final m = match.value;
    if (m == null) return;
    Get.toNamed(
      AppConstants.routes.matchChallengeMessages,
      arguments: {'match': m},
    );
  }
}
