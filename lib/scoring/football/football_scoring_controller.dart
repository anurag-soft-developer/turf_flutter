import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/query/query_keys.dart';
import '../../match_up/model/team_match_model.dart';
import '../shared/scoring_shared_models.dart';
import '../shared/scoring_socket_service.dart';
import 'football_scoring_api_service.dart';
import 'football_scoring_live_cache.dart';
import 'model/football_match_event_model.dart';
import 'model/football_scoring_models.dart';

/// Coordinates live football scoring for the current session.
class FootballScoringController extends GetxController {
  FootballScoringController({FootballScoringApiService? apiService})
    : _apiService = apiService ?? FootballScoringApiService();

  final FootballScoringApiService _apiService;

  final RxBool isConnected = false.obs;
  final RxBool isJoiningSession = false.obs;
  final RxBool isSendingUpdate = false.obs;
  final RxString currentSessionId = ''.obs;
  final RxnString errorMessage = RxnString();

  final Rxn<TeamMatchModel> footballMatch = Rxn<TeamMatchModel>();
  final RxBool isFetchingFootballMatch = false.obs;
  final RxBool isCreatingFootballSession = false.obs;
  final RxBool isCompletingFootballMatch = false.obs;
  final RxBool isChangingInning = false.obs;
  final RxBool isUpdatingTimer = false.obs;

  final RxList<FootballMatchEvent> footballEvents = <FootballMatchEvent>[].obs;
  final RxBool isFetchingEvents = false.obs;

  final List<AppendFootballEventRequest> _eventRequestHistory =
      <AppendFootballEventRequest>[];
  final List<AppendFootballEventRequest> _redoEventRequests =
      <AppendFootballEventRequest>[];
  final RxBool canRedoFootballEvent = false.obs;

  StreamSubscription<ScoringUpdatePayload>? _scoringSub;
  String? _joinedMatchId;

  bool get canUndoFootballEvent => footballEvents.isNotEmpty;

  ScoringSocketService? get _socket =>
      Get.isRegistered<ScoringSocketService>()
          ? Get.find<ScoringSocketService>()
          : null;

  String? get _currentUserId {
    if (!Get.isRegistered<AuthStateController>()) return null;
    return AuthStateController.instance.user?.id;
  }

  void seedFromQuery({
    TeamMatchModel? match,
    List<FootballMatchEvent>? events,
  }) {
    if (match != null) {
      footballMatch.value = match;
    }
    if (events != null) {
      footballEvents.assignAll(events);
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
    if (payload.sport != ScoringSport.football) return;

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

    if (footballMatch.value == null) {
      final sessionId = currentSessionId.value;
      if (sessionId.isNotEmpty) {
        unawaited(fetchFootballMatch(sessionId));
        if (footballEventsPatchPresent(payload)) {
          unawaited(fetchFootballEvents(sessionId));
        }
      }
      _patchLiveQueryCache(payload);
      return;
    }

    final current = footballMatch.value;
    if (current != null && footballMatchPatchPresent(data)) {
      footballMatch.value = patchFootballMatchFromData(current, data);
    }

    final patchedEvents = patchFootballEventsFromPayload(
      footballEvents.toList(),
      payload,
    );
    if (patchedEvents != null) {
      footballEvents.assignAll(patchedEvents);
      footballEvents.refresh();
    }

    if (payload.isFootballChangeInning || payload.isFootballCompleteMatch) {
      _resetEventHistory();
    }

    _patchLiveQueryCache(payload);
  }

  void _patchLiveQueryCache(ScoringUpdatePayload payload) {
    if (!Get.isRegistered<QueryClient>()) return;
    applyFootballScoringUpdateToCache(
      Get.find<QueryClient>(),
      payload,
      expectedMatchId: currentSessionId.value,
    );
  }

  void _syncQueryCache({bool includeEvents = true}) {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final id = currentSessionId.value;
    if (id.isEmpty) return;
    final match = footballMatch.value;
    if (match != null) {
      client.setQueryData<TeamMatchModel, Object>(
        QueryKeys.footballSession(id),
        (_) => match,
      );
      client.setQueryData<TeamMatchModel, Object>(
        QueryKeys.matchChallengeDetail(id),
        (_) => match,
      );
    }
    if (includeEvents) {
      final events = footballEvents.toList();
      client.setQueryData<List<FootballMatchEvent>, Object>(
        QueryKeys.footballEvents(id),
        (_) => events,
      );
    }
  }

  Future<void> _invalidateQueryCache({bool includeEvents = true}) async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    final id = currentSessionId.value;
    if (id.isEmpty) return;
    final futures = <Future<void>>[
      client.invalidateQueries(queryKey: QueryKeys.footballSession(id)),
      client.invalidateQueries(queryKey: QueryKeys.matchChallengeDetail(id)),
    ];
    if (includeEvents) {
      futures.add(
        client.invalidateQueries(queryKey: QueryKeys.footballEvents(id)),
      );
    }
    await Future.wait(futures);
  }

  /// Thin helper used after mutations / manual refresh.
  Future<void> fetchFootballMatch(String teamMatchId) async {
    if (teamMatchId.isEmpty) {
      errorMessage.value = 'Missing match id.';
      return;
    }
    isFetchingFootballMatch.value = true;
    errorMessage.value = null;
    final match = await _apiService.getFootballSession(teamMatchId);
    footballMatch.value = match;
    if (match == null) {
      errorMessage.value = 'Could not load match.';
    } else {
      _syncQueryCache(includeEvents: false);
    }
    isFetchingFootballMatch.value = false;
  }

  /// Thin helper used after mutations / manual refresh.
  Future<void> fetchFootballEvents(
    String teamMatchId, {
    bool resetEventHistory = false,
  }) async {
    if (teamMatchId.isEmpty) return;
    isFetchingEvents.value = true;
    errorMessage.value = null;
    try {
      final res = await _apiService.listFootballEvents(teamMatchId: teamMatchId);
      final sorted = List<FootballMatchEvent>.from(res)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      footballEvents.assignAll(sorted);
      if (resetEventHistory) {
        _resetEventHistory();
      }
      _syncQueryCache();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isFetchingEvents.value = false;
    }
  }

  void upsertFootballEvent(FootballMatchEvent event) {
    footballEvents.removeWhere((e) {
      if (event.id.isNotEmpty && e.id.isNotEmpty && e.id == event.id) {
        return true;
      }
      return e.sequence == event.sequence;
    });
    footballEvents.add(event);
    footballEvents.sort((a, b) => a.sequence.compareTo(b.sequence));
    footballEvents.refresh();
  }

  void _resetEventHistory() {
    _eventRequestHistory.clear();
    _redoEventRequests.clear();
    canRedoFootballEvent.value = false;
  }

  void _syncRedoAvailability() {
    canRedoFootballEvent.value = _redoEventRequests.isNotEmpty;
  }

  Future<bool> createFootballSession(
    CreateFootballSessionRequest request,
  ) async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }

    errorMessage.value = null;
    isCreatingFootballSession.value = true;
    final match = await _apiService.createFootballSession(
      teamMatchId: sessionId,
      request: request,
    );
    isCreatingFootballSession.value = false;
    if (match == null) {
      errorMessage.value = 'Could not start football session.';
      return false;
    }
    footballMatch.value = match;
    await fetchFootballEvents(sessionId, resetEventHistory: true);
    _syncQueryCache();
    return true;
  }

  bool get canChangeFootballInning {
    final fs = footballMatch.value?.footballState;
    if (fs == null) return false;
    return fs.currentInnings < fs.inningsSummaries.length;
  }

  Future<bool> changeFootballInning([
    ChangeFootballInningRequest request = const ChangeFootballInningRequest(),
  ]) async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }
    if (!canChangeFootballInning) {
      errorMessage.value = 'All innings are finished.';
      return false;
    }

    errorMessage.value = null;
    isChangingInning.value = true;
    try {
      final match = await _apiService.changeFootballInning(
        teamMatchId: sessionId,
        request: request,
      );
      if (match == null) {
        errorMessage.value = 'Could not change innings.';
        return false;
      }
      footballMatch.value = match;
      _syncQueryCache(includeEvents: false);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isChangingInning.value = false;
    }
  }

  Future<bool> pauseFootballTimer() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) return false;
    final fs = footballMatch.value?.footballState;
    if (fs == null || fs.isTimerPaused) return true;

    errorMessage.value = null;
    isUpdatingTimer.value = true;
    try {
      final match = await _apiService.pauseFootballTimer(teamMatchId: sessionId);
      if (match != null) {
        footballMatch.value = match;
        _syncQueryCache(includeEvents: false);
      }
      return match != null;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isUpdatingTimer.value = false;
    }
  }

  Future<bool> resumeFootballTimer() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) return false;
    final fs = footballMatch.value?.footballState;
    if (fs == null || !fs.isTimerPaused) return true;

    errorMessage.value = null;
    isUpdatingTimer.value = true;
    try {
      final match =
          await _apiService.resumeFootballTimer(teamMatchId: sessionId);
      if (match != null) {
        footballMatch.value = match;
        _syncQueryCache(includeEvents: false);
      }
      return match != null;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isUpdatingTimer.value = false;
    }
  }

  Future<bool> completeFootballMatch() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }

    errorMessage.value = null;
    isCompletingFootballMatch.value = true;
    try {
      final match = await _apiService.completeFootballMatch(
        teamMatchId: sessionId,
      );
      if (match == null) {
        errorMessage.value = 'Could not complete match.';
        return false;
      }
      footballMatch.value = match;
      _resetEventHistory();
      _syncQueryCache(includeEvents: false);
      await _invalidateQueryCache(includeEvents: false);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isCompletingFootballMatch.value = false;
    }
  }

  Future<FootballMatchEvent?> appendFootballEvent(
    AppendFootballEventRequest request,
  ) async {
    debugPrint('[FootballScoringController] appendFootballEvent: $request');
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No scoring session selected.';
      return null;
    }

    errorMessage.value = null;
    isSendingUpdate.value = true;
    try {
      final response = await _apiService.appendFootballEvent(
        teamMatchId: sessionId,
        request: request,
      );
      if (response == null) {
        errorMessage.value = 'Could not send event.';
        return null;
      }
      _eventRequestHistory.add(request);
      _redoEventRequests.clear();
      _syncRedoAvailability();
      upsertFootballEvent(response);
      final match = await _apiService.getFootballSession(sessionId);
      if (match != null) {
        footballMatch.value = match;
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

  Future<bool> undoLastFootballEvent() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No scoring session selected.';
      return false;
    }
    if (!canUndoFootballEvent) {
      errorMessage.value = 'No event to undo.';
      return false;
    }

    errorMessage.value = null;
    isSendingUpdate.value = true;
    try {
      final ok = await _apiService.undoLastFootballEvent(teamMatchId: sessionId);
      if (!ok) {
        errorMessage.value = 'Could not undo the last event.';
        return false;
      }
      if (_eventRequestHistory.isNotEmpty) {
        _redoEventRequests.add(_eventRequestHistory.removeLast());
        _syncRedoAvailability();
      }
      await fetchFootballEvents(sessionId);
      final match = await _apiService.getFootballSession(sessionId);
      if (match != null) {
        footballMatch.value = match;
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

  Future<bool> redoLastFootballEvent() async {
    if (_redoEventRequests.isEmpty) {
      errorMessage.value = 'Nothing to redo.';
      return false;
    }

    final request = _redoEventRequests.removeLast();
    _syncRedoAvailability();
    final event = await appendFootballEvent(request);
    if (event != null) {
      return true;
    }

    _redoEventRequests.add(request);
    _syncRedoAvailability();
    return false;
  }

  @override
  void onClose() {
    unawaited(leaveLiveSession());
    super.onClose();
  }
}
