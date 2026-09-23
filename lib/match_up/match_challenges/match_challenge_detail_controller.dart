import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/challenges/praposals/propose_time_slot_sheet.dart';
import '../../components/challenges/praposals/propose_turf_sheet.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/routes/route_query.dart';
import '../../core/utils/app_snackbar.dart';
import '../../scoring/cricket/cricket_scoring_live_cache.dart';
import '../../scoring/football/football_scoring_live_cache.dart';
import '../../scoring/shared/scoring_shared_models.dart';
import '../../scoring/shared/scoring_socket_service.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import 'match_incoming_resolver.dart';

/// Tab + mutation state for challenge detail.
class MatchChallengeDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  MatchChallengeDetailController({required this.matchId});

  /// Captured once at open (binding). Do not re-read [Get.parameters] after push.
  final String matchId;
  late final bool? explicitIsIncoming;

  final Rxn<TeamMatchModel> match = Rxn<TeamMatchModel>();
  final RxBool isIncoming = false.obs;

  /// Match team ids the current user belongs to (from and/or to).
  final Rx<Set<String>> myMatchTeamIds = Rx<Set<String>>({});

  final RxBool isBootstrapping = false.obs;
  final RxnString loadError = RxnString();

  final MatchmakingService _matchmakingService = MatchmakingService();
  final TeamService _teamService = TeamService();

  late final TabController detailTabController;

  final RxBool isUpdatingSlot = false.obs;
  final RxBool isUpdatingTurf = false.obs;
  final RxBool isRejectingChallenge = false.obs;
  final RxBool isAcceptingChallenge = false.obs;
  final RxBool isCancellingMatch = false.obs;

  StreamSubscription<ScoringUpdatePayload>? _scoringSub;
  String? _joinedLiveMatchId;
  Set<String> _myTeamIds = {};

  String? get resolvedMatchId {
    final fromMatch = match.value?.id;
    if (fromMatch != null && fromMatch.isNotEmpty) return fromMatch;
    final arg = matchId.trim();
    if (arg.isNotEmpty) return arg;
    return null;
  }

  bool get actionBusy =>
      isUpdatingSlot.value ||
      isUpdatingTurf.value ||
      isRejectingChallenge.value ||
      isAcceptingChallenge.value ||
      isCancellingMatch.value;

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

  /// Teams on this match the user can announce for.
  Set<String> get editableAnnounceTeamIds => myMatchTeamIds.value;

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

  bool get canUseScheduleControls => canEditSchedule && !isCancellingMatch.value;

  bool get isUnranked => match.value?.isUnranked == true;

  bool get isAbandonMatch => match.value?.status == TeamMatchStatus.ongoing;

  bool get canCancelOrAbandonMatch {
    return switch (match.value?.status) {
      TeamMatchStatus.requested ||
      TeamMatchStatus.accepted ||
      TeamMatchStatus.negotiating ||
      TeamMatchStatus.scheduleFinalized ||
      TeamMatchStatus.ongoing =>
        myTeamId.isNotEmpty,
      _ => false,
    };
  }

  ScoringSocketService? get _socket =>
      Get.isRegistered<ScoringSocketService>()
          ? Get.find<ScoringSocketService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    detailTabController = TabController(length: 3, vsync: this);
    final args = Get.arguments;
    if (args is Map && args['isIncoming'] is bool) {
      explicitIsIncoming = args['isIncoming'] as bool;
    } else {
      explicitIsIncoming = routeParamBool('isIncoming');
    }
    if (explicitIsIncoming != null) {
      isIncoming.value = explicitIsIncoming!;
    }
    unawaited(bootstrap());
  }

  @override
  void onClose() {
    unawaited(_teardownLiveScoringUpdates());
    detailTabController.dispose();
    super.onClose();
  }

  Future<void> bootstrap() async {
    if (matchId.isEmpty) {
      loadError.value = 'Challenge not found.';
      isBootstrapping.value = false;
      return;
    }
    isBootstrapping.value = true;
    loadError.value = null;
    await Future.wait([_fetchMatch(), _fetchMemberships()]);
    if (isClosed) return;
    _applyMembershipContext();
    isBootstrapping.value = false;
    if (isCricketMatch || isFootballMatch) {
      unawaited(_ensureLiveScoringUpdates());
    }
  }

  Future<void> reload() => bootstrap();

  Future<void> _fetchMatch() async {
    try {
      final loaded = await _matchmakingService.getTeamMatchById(matchId);
      if (isClosed) return;
      if (loaded == null) {
        loadError.value = 'Could not load challenge.';
        match.value = null;
        return;
      }
      match.value = loaded;
      _syncDetailQueryCache(loaded);
    } catch (e) {
      if (!isClosed) loadError.value = e.toString();
    }
  }

  Future<void> _fetchMemberships() async {
    try {
      final res = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      if (isClosed) return;
      final ids = <String>{};
      for (final m in res?.data ?? const <TeamMemberModel>[]) {
        final t = m.team;
        if (t is TeamMemberFieldInstance &&
            t.id != null &&
            t.id!.isNotEmpty) {
          ids.add(t.id!);
        }
      }
      _myTeamIds = ids;
    } catch (_) {
      // Membership failure should not block match view; keep prior ids.
    }
  }

  void _applyMembershipContext() {
    final current = match.value;
    if (current == null) {
      if (explicitIsIncoming != null) {
        isIncoming.value = explicitIsIncoming!;
      }
      return;
    }
    final fromId = current.fromTeamHelper.getId();
    final toId = current.toTeamHelper.getId();
    final onMatch = <String>{
      if (fromId != null && _myTeamIds.contains(fromId)) fromId,
      if (toId != null && _myTeamIds.contains(toId)) toId,
    };
    myMatchTeamIds.value = onMatch;
    if (explicitIsIncoming != null) {
      isIncoming.value = explicitIsIncoming!;
    } else {
      isIncoming.value = resolveIsIncoming(current, _myTeamIds);
    }
  }

  void _syncDetailQueryCache(TeamMatchModel loaded) {
    if (!Get.isRegistered<QueryClient>()) return;
    final id = loaded.id;
    if (id == null || id.isEmpty) return;
    Get.find<QueryClient>().setQueryData<TeamMatchModel, Object>(
      QueryKeys.matchChallengeDetail(id),
      (_) => loaded,
    );
  }

  void syncMatch(TeamMatchModel? value) {
    if (value == null) return;
    match.value = value;
    if (value.sportType == TeamSportType.cricket ||
        value.sportType == TeamSportType.football) {
      unawaited(_ensureLiveScoringUpdates());
    }
  }

  Future<void> _ensureLiveScoringUpdates() async {
    final id = resolvedMatchId?.trim();
    if (id == null || id.isEmpty) return;
    if (_joinedLiveMatchId == id && _scoringSub != null) return;

    final socket = _socket;
    if (socket == null) return;

    if (_joinedLiveMatchId != null && _joinedLiveMatchId != id) {
      await _teardownLiveScoringUpdates();
    }

    _scoringSub ??= socket.updates.listen(_onScoringUpdate);
    await socket.joinMatch(id);
    _joinedLiveMatchId = id;
  }

  Future<void> _teardownLiveScoringUpdates() async {
    final id = _joinedLiveMatchId;
    _joinedLiveMatchId = null;
    await _scoringSub?.cancel();
    _scoringSub = null;
    if (id == null || id.isEmpty) return;
    try {
      await _socket?.leaveMatch(id);
    } catch (e, st) {
      debugPrint('detail leaveLiveMatch failed: $e\n$st');
    }
  }

  void _onScoringUpdate(ScoringUpdatePayload payload) {
    final id = _joinedLiveMatchId ?? resolvedMatchId;
    if (id == null || id.isEmpty) return;
    if (payload.teamMatchId != id) return;
    if (!Get.isRegistered<QueryClient>()) return;

    final client = Get.find<QueryClient>();
    if (payload.sport == ScoringSport.cricket) {
      applyCricketScoringUpdateToCache(
        client,
        payload,
        expectedMatchId: id,
      );
    } else if (payload.sport == ScoringSport.football) {
      applyFootballScoringUpdateToCache(
        client,
        payload,
        expectedMatchId: id,
      );
    }
    final updated = client.getQueryData<TeamMatchModel>(
      QueryKeys.matchChallengeDetail(id),
    );
    if (updated != null) syncMatch(updated);
  }

  void syncIsIncoming(bool value) {
    isIncoming.value = value;
  }

  void syncMyMatchTeamIds(Set<String> ids) {
    myMatchTeamIds.value = ids;
  }

  void scheduleMatchUpdate(TeamMatchModel updated) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      match.value = updated;
      _applyMembershipContext();
      _invalidateMatchQueries(updated);
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
    final id = match.value?.id;
    if (id == null || id.isEmpty || myTeamId.isEmpty) return;

    if (action == MatchResponseAction.reject) {
      isRejectingChallenge.value = true;
    } else {
      isAcceptingChallenge.value = true;
    }

    final updated = await _matchmakingService.respond(
      id,
      RespondMatchRequest(actorTeamId: myTeamId, action: action),
    );

    isRejectingChallenge.value = false;
    isAcceptingChallenge.value = false;

    if (updated == null) return;

    match.value = updated;
    await _invalidateMatchQueries(updated);
    AppSnackbar.success(
      title: action == MatchResponseAction.accept
          ? (isUnranked ? 'Request accepted' : 'Challenge accepted')
          : (isUnranked ? 'Request rejected' : 'Challenge rejected'),
      message: action == MatchResponseAction.accept
          ? 'You can continue scheduling now.'
          : (isUnranked
              ? 'The unranked match request was declined.'
              : 'The challenge was declined.'),
    );
  }

  Future<void> cancelOrAbandonMatch({String? reason}) async {
    if (actionBusy) return;
    if (!canCancelOrAbandonMatch) return;
    final id = match.value?.id;
    if (id == null || id.isEmpty || myTeamId.isEmpty) return;

    final abandon = isAbandonMatch;
    isCancellingMatch.value = true;
    final updated = await _matchmakingService.cancel(
      id,
      CancelNegotiationRequest(
        actorTeamId: myTeamId,
        reason: reason,
      ),
    );
    isCancellingMatch.value = false;

    if (updated == null) return;

    match.value = updated;
    await _invalidateMatchQueries(updated);
    AppSnackbar.success(
      title: abandon ? 'Match abandoned' : 'Match cancelled',
      message: abandon
          ? 'This match has been abandoned.'
          : 'This match has been cancelled.',
    );
  }

  Future<void> setTimeSlot(BuildContext context) async {
    if (actionBusy) return;
    final id = match.value?.id;
    if (id == null || id.isEmpty || myTeamId.isEmpty) return;

    final selected = await showModalBottomSheet<ProposeScheduleTimeSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposeTimeSlotSheet(),
    );
    if (selected == null) return;

    isUpdatingSlot.value = true;
    final updated = await _matchmakingService.updateRequest(
      id,
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
    final id = match.value?.id;
    if (id == null || id.isEmpty || myTeamId.isEmpty) return;

    final selectedTurfId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => ProposeTurfSheet(
        sportTypes: [match.value!.sportType.name],
      ),
    );
    if (selectedTurfId == null || selectedTurfId.isEmpty) return;

    isUpdatingTurf.value = true;
    final updated = await _matchmakingService.updateRequest(
      id,
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

  Future<void> openScoreboard() async {
    final id = match.value?.id;
    if (id == null || id.isEmpty) {
      AppSnackbar.error(
        title: 'Missing match id',
        message: 'Unable to open scoreboard for this challenge.',
      );
      return;
    }
    final route = isFootballMatch
        ? AppConstants.routes.footballScoreBoard
        : AppConstants.routes.cricketScoreBoard;
    await Get.toNamed(route, arguments: {'matchId': id});
    if (!isClosed) await loadMatchQuiet();
  }

  /// Refresh match after returning from scoreboard without full bootstrap spinner.
  Future<void> loadMatchQuiet() async {
    await _fetchMatch();
    if (!isClosed) _applyMembershipContext();
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
