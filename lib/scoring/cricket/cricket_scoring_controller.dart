import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/query/query_keys.dart';
import '../../match_up/model/team_match_model.dart';
import '../shared/scoring_shared_models.dart';
import '../shared/scoring_socket_service.dart';
import 'cricket_scoring_api_service.dart';
import 'cricket_scoring_live_cache.dart';
import 'model/cricket_over_event_model.dart';
import 'model/cricket_scoring_models.dart';

/// Coordinates live cricket scoring for the current session.
class CricketScoringController extends GetxController {
  CricketScoringController({CricketScoringApiService? apiService})
    : _apiService = apiService ?? CricketScoringApiService();

  final CricketScoringApiService _apiService;

  static const int minOvers = 1;
  static const int maxOversLimit = 120;

  final RxBool isConnected = false.obs;
  final RxBool isJoiningSession = false.obs;
  final RxBool isSendingUpdate = false.obs;
  final RxString currentSessionId = ''.obs;
  final RxnString errorMessage = RxnString();

  final Rxn<TeamMatchModel> cricketMatch = Rxn<TeamMatchModel>();

  final RxBool isFetchingCricketMatch = false.obs;
  final RxBool isCreatingCricketSession = false.obs;
  final RxBool isUpdatingCricketLineup = false.obs;
  final RxBool isChangingCricketInning = false.obs;
  final RxBool isCompletingCricketMatch = false.obs;

  final RxList<CricketOverEvent> cricketOvers = <CricketOverEvent>[].obs;
  final RxBool isFetchingOvers = false.obs;

  /// Start-session UI: who bats first (empty until user picks).
  final RxString battingTeamId = ''.obs;

  /// Bumps when overs text changes so Obx can recompute [canSubmitStart].
  final RxInt maxOversRevision = 0.obs;

  late final TextEditingController maxOversController;

  final List<AppendCricketBallRequest> _ballRequestHistory =
      <AppendCricketBallRequest>[];
  final List<AppendCricketBallRequest> _redoBallRequests =
      <AppendCricketBallRequest>[];
  final RxBool canRedoCricketBall = false.obs;

  StreamSubscription<ScoringUpdatePayload>? _scoringSub;
  String? _joinedMatchId;

  bool get canUndoCricketBall =>
      cricketOvers.any((over) => over.events.isNotEmpty);

  String get fromTeamId =>
      cricketMatch.value?.fromTeamHelper.getId() ?? '';

  String get toTeamId => cricketMatch.value?.toTeamHelper.getId() ?? '';

  String get fromTeamName =>
      cricketMatch.value?.fromTeamHelper.getDisplayName() ?? '';

  String get toTeamName =>
      cricketMatch.value?.toTeamHelper.getDisplayName() ?? '';

  String get bowlingTeamIdResolved {
    final bat = battingTeamId.value;
    if (bat.isEmpty) return '';
    if (bat == fromTeamId) return toTeamId;
    if (bat == toTeamId) return fromTeamId;
    return '';
  }

  int? get parsedMaxOvers {
    // Depend on revision so Obx rebuilds when the text field changes.
    maxOversRevision.value;
    final t = maxOversController.text.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return null;
    if (n < minOvers || n > maxOversLimit) return null;
    return n;
  }

  bool get canSubmitStart =>
      battingTeamId.value.isNotEmpty &&
      fromTeamId.isNotEmpty &&
      toTeamId.isNotEmpty &&
      bowlingTeamIdResolved.isNotEmpty &&
      parsedMaxOvers != null;

  ScoringSocketService? get _socket =>
      Get.isRegistered<ScoringSocketService>()
          ? Get.find<ScoringSocketService>()
          : null;

  String? get _currentUserId {
    if (!Get.isRegistered<AuthStateController>()) return null;
    return AuthStateController.instance.user?.id;
  }

  @override
  void onInit() {
    super.onInit();
    maxOversController = TextEditingController(text: '20');
  }

  /// Bind scoreboard to a match id; resets start-session UI when the id changes.
  void bindScoreboard(String teamMatchId) {
    final id = teamMatchId.trim();
    if (currentSessionId.value != id) {
      battingTeamId.value = '';
      maxOversController.text = '20';
      maxOversRevision.value = 0;
      cricketMatch.value = null;
      cricketOvers.clear();
      errorMessage.value = null;
      _resetCricketBallHistory();
    }
    currentSessionId.value = id;
  }

  void setBattingTeamId(String id) {
    battingTeamId.value = id;
  }

  void onMaxOversChanged() {
    maxOversRevision.value++;
  }

  String teamLabelForId(String teamId) {
    if (teamId.isEmpty) return '—';
    if (teamId == fromTeamId) {
      return fromTeamName.isNotEmpty ? fromTeamName : 'Team';
    }
    if (teamId == toTeamId) {
      return toTeamName.isNotEmpty ? toTeamName : 'Team';
    }
    return 'Team';
  }

  void seedFromQuery({
    TeamMatchModel? match,
    List<CricketOverEvent>? overs,
  }) {
    if (match != null) {
      final current = cricketMatch.value;
      // Don't clobber an active scoring session with a meta-only payload.
      if (current?.cricketState != null && match.cricketState == null) {
        // keep current
      } else {
        cricketMatch.value = match;
      }
    }
    if (overs != null) {
      cricketOvers.assignAll(overs);
    }
  }

  Future<void> joinLiveSession(String teamMatchId) async {
    final id = teamMatchId.trim();
    if (id.isEmpty) return;

    final previous = _joinedMatchId;
    if (previous != null && previous != id) {
      await leaveLiveSession();
    }

    isJoiningSession.value = true;
    try {
      final socket = _socket;
      if (socket == null) {
        isConnected.value = false;
        return;
      }
      _scoringSub ??= socket.updates.listen(_onScoringUpdate);
      await socket.joinMatch(id);
      _joinedMatchId = id;
      isConnected.value = socket.isConnected;
    } catch (e, st) {
      debugPrint('joinLiveSession failed: $e\n$st');
      isConnected.value = false;
    } finally {
      isJoiningSession.value = false;
    }
  }

  Future<void> leaveLiveSession() async {
    final id = _joinedMatchId;
    _joinedMatchId = null;
    await _scoringSub?.cancel();
    _scoringSub = null;
    isConnected.value = false;
    if (id == null || id.isEmpty) return;
    try {
      await _socket?.leaveMatch(id);
    } catch (e, st) {
      debugPrint('leaveLiveSession failed: $e\n$st');
    }
  }

  void _onScoringUpdate(ScoringUpdatePayload payload) {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty || payload.teamMatchId != sessionId) return;
    if (payload.sport != ScoringSport.cricket) return;

    final actorId = payload.actorUserId;
    final me = _currentUserId;
    if (me != null && me.isNotEmpty && actorId == me) {
      // Actor already applied the HTTP response locally.
      return;
    }

    try {
      _applyRemoteUpdate(payload);
    } catch (e, st) {
      debugPrint('apply remote scoring update failed: $e\n$st');
    }
  }

  void _applyRemoteUpdate(ScoringUpdatePayload payload) {
    final data = payload.data;

    if (cricketMatch.value == null) {
      final sessionId = currentSessionId.value;
      if (sessionId.isNotEmpty) {
        unawaited(fetchCricketMatch(sessionId));
        if (payload.action == ScoringAction.appendBall ||
            payload.action == ScoringAction.appendSubstitution ||
            payload.action == ScoringAction.undoBall ||
            payload.action == ScoringAction.undoScoringEntry) {
          unawaited(fetchCricketOvers(sessionId));
        }
      }
      _patchLiveQueryCache(payload);
      return;
    }

    final current = cricketMatch.value;
    if (current != null && cricketMatchPatchPresent(data)) {
      cricketMatch.value = patchCricketMatchFromData(current, data);
    }

    final patchedOvers = patchCricketOversFromPayload(
      cricketOvers.toList(),
      payload,
    );
    if (patchedOvers != null) {
      cricketOvers.assignAll(patchedOvers);
      cricketOvers.refresh();
    }

    if (payload.isCricketChangeInning || payload.isCricketCompleteMatch) {
      _resetCricketBallHistory();
    }

    _patchLiveQueryCache(payload);
  }

  void _patchLiveQueryCache(ScoringUpdatePayload payload) {
    if (!Get.isRegistered<QueryClient>()) return;
    applyCricketScoringUpdateToCache(
      Get.find<QueryClient>(),
      payload,
      expectedMatchId: currentSessionId.value,
    );
  }

  void _syncQueryCache({bool includeOvers = true}) {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final id = currentSessionId.value;
    if (id.isEmpty) return;
    final match = cricketMatch.value;
    if (match != null) {
      client.setQueryData<TeamMatchModel, Object>(
        QueryKeys.cricketSession(id),
        (_) => match,
      );
      client.setQueryData<TeamMatchModel, Object>(
        QueryKeys.matchChallengeDetail(id),
        (_) => match,
      );
    }
    if (includeOvers) {
      final overs = cricketOvers.toList();
      client.setQueryData<List<CricketOverEvent>, Object>(
        QueryKeys.cricketOvers(id),
        (_) => overs,
      );
    }
  }

  Future<void> _invalidateQueryCache({bool includeOvers = true}) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final id = currentSessionId.value;
    if (id.isEmpty) return;
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: QueryKeys.cricketSession(id)),
      client.invalidateQueries(queryKey: QueryKeys.matchChallengeDetail(id)),
    ];
    if (includeOvers) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.cricketOvers(id)),
      );
    }
    await Future.wait(futures);
  }

  /// Thin helper used after mutations / manual refresh.
  Future<void> fetchCricketMatch(String teamMatchId) async {
    if (teamMatchId.isEmpty) {
      errorMessage.value = 'Missing match id.';
      return;
    }
    isFetchingCricketMatch.value = true;
    errorMessage.value = null;
    final match = await _apiService.getCricketSession(teamMatchId);
    cricketMatch.value = match;
    if (match == null) {
      errorMessage.value = 'Could not load match.';
    } else {
      _syncQueryCache(includeOvers: false);
    }
    isFetchingCricketMatch.value = false;
  }

  /// Thin helper used after mutations / manual refresh.
  Future<void> fetchCricketOvers(
    String teamMatchId, {
    bool resetBallHistory = false,
  }) async {
    if (teamMatchId.isEmpty) return;
    isFetchingOvers.value = true;
    errorMessage.value = null;
    try {
      final res = await _apiService.listCricketOvers(teamMatchId: teamMatchId);
      final sorted = List<CricketOverEvent>.from(res)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      cricketOvers.assignAll(sorted);
      if (resetBallHistory) {
        _resetCricketBallHistory();
      }
      _syncQueryCache();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isFetchingOvers.value = false;
    }
  }

  void upsertCricketOver(CricketOverEvent over) {
    cricketOvers.assignAll(upsertCricketOverInList(cricketOvers.toList(), over));
    cricketOvers.refresh();
  }

  void removeCricketOver(String overId) {
    cricketOvers.assignAll(
      removeCricketOverFromList(cricketOvers.toList(), overId),
    );
    cricketOvers.refresh();
  }

  void _resetCricketBallHistory() {
    _ballRequestHistory.clear();
    _redoBallRequests.clear();
    canRedoCricketBall.value = false;
  }

  void _syncRedoAvailability() {
    canRedoCricketBall.value = _redoBallRequests.isNotEmpty;
  }

  Future<bool> createCricketSession(CreateCricketSessionRequest request) async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }

    errorMessage.value = null;
    isCreatingCricketSession.value = true;
    final match = await _apiService.createCricketSession(
      teamMatchId: sessionId,
      request: request,
    );
    isCreatingCricketSession.value = false;
    if (match == null) return false;
    cricketMatch.value = match;
    await fetchCricketOvers(sessionId, resetBallHistory: true);
    _syncQueryCache();
    return true;
  }

  Future<bool> updateCricketState(UpdateCricketStateRequest request) async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }
    errorMessage.value = null;
    isUpdatingCricketLineup.value = true;
    final match = await _apiService.updateCricketState(
      teamMatchId: sessionId,
      request: request,
    );
    if (match != null) {
      cricketMatch.value = match;
      _syncQueryCache(includeOvers: false);
    }
    isUpdatingCricketLineup.value = false;
    return match != null;
  }

  Future<bool> completeCricketMatch() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }

    errorMessage.value = null;
    isCompletingCricketMatch.value = true;
    try {
      final match = await _apiService.completeCricketMatch(
        teamMatchId: sessionId,
      );
      if (match == null) return false;
      cricketMatch.value = match;
      _resetCricketBallHistory();
      _syncQueryCache(includeOvers: false);
      await _invalidateQueryCache(includeOvers: false);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isCompletingCricketMatch.value = false;
    }
  }

  Future<bool> changeCricketInning() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }

    errorMessage.value = null;
    isChangingCricketInning.value = true;
    try {
      final match = await _apiService.changeCricketInning(teamMatchId: sessionId);
      if (match == null) return false;
      cricketMatch.value = match;
      _resetCricketBallHistory();
      _syncQueryCache(includeOvers: false);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isChangingCricketInning.value = false;
    }
  }

  Future<CricketOverEvent?> appendCricketBall(
    AppendCricketBallRequest request,
  ) async {
    debugPrint('[CricketScoringController] appendCricketBall: $request');
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No scoring session selected.';
      return null;
    }

    errorMessage.value = null;
    isSendingUpdate.value = true;
    try {
      final response = await _apiService.appendCricketBall(
        teamMatchId: sessionId,
        request: request,
      );
      if (response == null) return null;
      _ballRequestHistory.add(request);
      _redoBallRequests.clear();
      _syncRedoAvailability();
      upsertCricketOver(response);
      final match = await _apiService.getCricketSession(sessionId);
      if (match != null) {
        cricketMatch.value = match;
      }
      _syncQueryCache();
      return response;
    } catch (error) {
      errorMessage.value = error.toString();
      return null;
    } finally {
      isSendingUpdate.value = false;
    }
  }

  Future<CricketOverEvent?> appendCricketSubstitution({
    required String teamId,
    required String playerOffParticipantId,
    required String playerOnParticipantId,
  }) async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No scoring session selected.';
      return null;
    }

    errorMessage.value = null;
    isSendingUpdate.value = true;
    try {
      final response = await _apiService.appendCricketSubstitution(
        teamMatchId: sessionId,
        teamId: teamId,
        playerOffParticipantId: playerOffParticipantId,
        playerOnParticipantId: playerOnParticipantId,
      );
      if (response == null) return null;
      _redoBallRequests.clear();
      _syncRedoAvailability();
      upsertCricketOver(response);
      final match = await _apiService.getCricketSession(sessionId);
      if (match != null) {
        cricketMatch.value = match;
      }
      _syncQueryCache();
      return response;
    } catch (error) {
      errorMessage.value = error.toString();
      return null;
    } finally {
      isSendingUpdate.value = false;
    }
  }

  Future<bool> undoLastCricketBall() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No scoring session selected.';
      return false;
    }
    if (!canUndoCricketBall) {
      errorMessage.value = 'No scoring entry to undo.';
      return false;
    }

    errorMessage.value = null;
    isSendingUpdate.value = true;
    try {
      final ok = await _apiService.undoLastCricketScoringEntry(
        teamMatchId: sessionId,
      );
      if (!ok) return false;
      if (_ballRequestHistory.isNotEmpty) {
        _redoBallRequests.add(_ballRequestHistory.removeLast());
        _syncRedoAvailability();
      }
      await fetchCricketOvers(sessionId);
      final match = await _apiService.getCricketSession(sessionId);
      if (match != null) {
        cricketMatch.value = match;
      }
      _syncQueryCache();
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isSendingUpdate.value = false;
    }
  }

  Future<bool> redoLastCricketBall() async {
    if (_redoBallRequests.isEmpty) {
      errorMessage.value = 'Nothing to redo.';
      return false;
    }

    final request = _redoBallRequests.removeLast();
    _syncRedoAvailability();
    final over = await appendCricketBall(request);
    if (over != null) {
      return true;
    }

    _redoBallRequests.add(request);
    _syncRedoAvailability();
    return false;
  }

  @override
  void onClose() {
    maxOversController.dispose();
    unawaited(leaveLiveSession());
    super.onClose();
  }
}
