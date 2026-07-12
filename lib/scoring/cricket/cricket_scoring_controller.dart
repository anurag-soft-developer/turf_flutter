import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../match_up/model/team_match_model.dart';
import 'cricket_scoring_api_service.dart';
import 'model/cricket_ball_event_model.dart';
import 'model/cricket_scoring_models.dart';

/// Coordinates live cricket scoring for the current session.
class CricketScoringController extends GetxController {
  CricketScoringController({CricketScoringApiService? apiService})
    : _apiService = apiService ?? CricketScoringApiService();

  final CricketScoringApiService _apiService;

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

  final List<AppendCricketBallRequest> _ballRequestHistory =
      <AppendCricketBallRequest>[];
  final List<AppendCricketBallRequest> _redoBallRequests =
      <AppendCricketBallRequest>[];
  final RxBool canRedoCricketBall = false.obs;

  bool get canUndoCricketBall =>
      cricketOvers.any((over) => over.ballEvents.isNotEmpty);

  void seedFromQuery({
    TeamMatchModel? match,
    List<CricketOverEvent>? overs,
  }) {
    if (match != null) {
      cricketMatch.value = match;
    }
    if (overs != null) {
      cricketOvers.assignAll(overs);
    }
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
    cricketOvers.removeWhere((o) {
      if (over.id.isNotEmpty && o.id.isNotEmpty && o.id == over.id) {
        return true;
      }
      return o.innings == over.innings &&
          o.overAfter == over.overAfter &&
          o.sequence == over.sequence;
    });
    cricketOvers.add(over);
    cricketOvers.sort((a, b) => a.sequence.compareTo(b.sequence));
    cricketOvers.refresh();
  }

  void removeCricketOver(String overId) {
    if (overId.isEmpty) return;
    cricketOvers.removeWhere((over) => over.id == overId);
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
    if (match == null) {
      errorMessage.value = 'Could not start cricket session.';
      return false;
    }
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
      if (match == null) {
        errorMessage.value = 'Could not complete match.';
        return false;
      }
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
      if (match == null) {
        errorMessage.value = 'Could not change innings.';
        return false;
      }
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
      if (response == null) {
        errorMessage.value = 'Could not send ball event.';
        return null;
      }
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

  Future<bool> undoLastCricketBall() async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No scoring session selected.';
      return false;
    }
    if (!canUndoCricketBall) {
      errorMessage.value = 'No ball to undo.';
      return false;
    }

    errorMessage.value = null;
    isSendingUpdate.value = true;
    try {
      final ok = await _apiService.undoLastCricketBall(teamMatchId: sessionId);
      if (!ok) {
        errorMessage.value = 'Could not undo the last ball.';
        return false;
      }
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
}
