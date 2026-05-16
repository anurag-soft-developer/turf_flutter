import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../match_up/model/team_match_model.dart';
import 'model/cricket_ball_event_model.dart';
import 'model/scoring_models.dart';
import 'scoring_api_service.dart';
// import 'scoring_socket_service.dart';

/// Coordinates live scoring for the current session.
///
/// Writes go to turf-services over HTTP. Real-time updates (including the
/// echo for the writer's own action) come back over a websocket subscribed
/// to `scoring:match:<teamMatchId>` on the realtime service.
class ScoringController extends GetxController {
  ScoringController({ScoringApiService? apiService})
    : _apiService = apiService ?? ScoringApiService();

  final ScoringApiService _apiService;

  final RxBool isConnected = false.obs;
  final RxBool isJoiningSession = false.obs;
  final RxBool isSendingUpdate = false.obs;
  final RxString currentSessionId = ''.obs;
  final RxnString errorMessage = RxnString();

  /// Latest cricket match document from `GET /scoring/cricket/matches/:id`.
  final Rxn<TeamMatchModel> cricketMatch = Rxn<TeamMatchModel>();

  final RxBool isFetchingCricketMatch = false.obs;

  final RxBool isCreatingCricketSession = false.obs;

  final RxBool isUpdatingCricketLineup = false.obs;

  final RxBool isChangingCricketInning = false.obs;

  final RxBool isCompletingCricketMatch = false.obs;

  /// Overs loaded from `GET .../overs` and updated after each `append_ball`.
  final RxList<CricketOverEvent> cricketOvers = <CricketOverEvent>[].obs;
  final RxBool isFetchingOvers = false.obs;

  final List<AppendCricketBallRequest> _ballRequestHistory =
      <AppendCricketBallRequest>[];
  final List<AppendCricketBallRequest> _redoBallRequests =
      <AppendCricketBallRequest>[];
  final RxBool canRedoCricketBall = false.obs;

  bool get canUndoCricketBall =>
      cricketOvers.any((over) => over.ballEvents.isNotEmpty);

  /// Loads scoring state and embedded [CricketStateModel] from turf-services.
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
    }

    isFetchingCricketMatch.value = false;
  }

  /// Loads all overs for the match.
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

  /// `POST /scoring/cricket/matches/:id/session` — initializes cricket scoring.
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
    return true;
  }

  /// `PATCH /scoring/cricket/matches/:id/state` — striker / non-striker / bowler.
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
    }
    isUpdatingCricketLineup.value = false;
    return match != null;
  }

  /// `POST /scoring/cricket/matches/:id/complete`
  Future<bool> completeCricketMatch(CompleteCricketMatchRequest request) async {
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
        request: request,
      );
      if (match == null) {
        errorMessage.value = 'Could not complete match.';
        return false;
      }
      cricketMatch.value = match;
      _resetCricketBallHistory();
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isCompletingCricketMatch.value = false;
    }
  }

  /// `POST /scoring/cricket/matches/:id/inning/change`
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
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isChangingCricketInning.value = false;
    }
  }

  /// Persists a cricket ball over HTTP and merges the returned over into
  /// [cricketOvers].
  Future<CricketOverEvent?> appendCricketBall(
    AppendCricketBallRequest request,
  ) async {
    debugPrint('[ScoringController] appendCricketBall: $request');
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
      debugPrint('[ScoringController] appended over id=${response.id}');
      final match = await _apiService.getCricketSession(sessionId);
      if (match != null) {
        cricketMatch.value = match;
      }
      return response;
    } catch (error) {
      errorMessage.value = error.toString();
      return null;
    } finally {
      isSendingUpdate.value = false;
    }
  }

  /// Removes the latest delivery on the server and keeps redoable requests
  /// locally for [redoLastCricketBall].
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
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    } finally {
      isSendingUpdate.value = false;
    }
  }

  /// Replays the most recently undone delivery using the existing append API.
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
