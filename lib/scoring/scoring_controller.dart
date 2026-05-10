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
  ScoringController({
    // ScoringSocketService? socketService,
    ScoringApiService? apiService,
  }) : // _socketService = socketService ?? ScoringSocketService(),
       _apiService = apiService ?? ScoringApiService();

  // final ScoringSocketService _socketService;
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

  /// Overs loaded from `GET .../overs` and updated after each `append_ball`.
  final RxList<CricketOverEvent> cricketOvers = <CricketOverEvent>[].obs;
  final RxBool isFetchingOvers = false.obs;

  // StreamSubscription<ScoringUpdatePayload>? _updatesSub;

  // @override
  // void onInit() {
  //   super.onInit();
  //   _updatesSub = _socketService.updatesStream.listen((update) {
  //     _addOrReplaceEvent(update);
  //   });
  // }

  // Future<void> connectAndJoin(String sessionId) async {
  //   if (sessionId.isEmpty) return;
  //   if (isConnected.value && currentSessionId.value == sessionId) return;
  //   errorMessage.value = null;
  //   isJoiningSession.value = true;

  //   try {
  //     if (currentSessionId.value.isNotEmpty &&
  //         currentSessionId.value != sessionId) {
  //       await leaveSession();
  //     }
  //     await _socketService.connect();
  //     isConnected.value = _socketService.isConnected;
  //     await _socketService.joinSession(sessionId);
  //     currentSessionId.value = sessionId;
  //     timeline.clear();
  //     debugPrint('[ScoringController] joined session=$sessionId');
  //   } catch (error) {
  //     errorMessage.value = error.toString();
  //     rethrow;
  //   } finally {
  //     isJoiningSession.value = false;
  //   }
  // }

  /// Loads scoring state and embedded [CricketStateModel] from turf-services.
  Future<void> fetchCricketMatch(String teamMatchId) async {
    if (teamMatchId.isEmpty) {
      errorMessage.value = 'Missing match id.';
      return;
    }
    isFetchingCricketMatch.value = true;
    errorMessage.value = null;
    // try {
    final match = await _apiService.getCricketSession(teamMatchId);
    cricketMatch.value = match;
    if (match == null) {
      errorMessage.value = 'Could not load match.';
    }
    // } catch (error) {
    //   cricketMatch.value = null;
    //   errorMessage.value = error.toString();
    // } finally {
    isFetchingCricketMatch.value = false;
    // }
  }

  /// Loads all overs for the match.
  Future<void> fetchCricketOvers(String teamMatchId) async {
    if (teamMatchId.isEmpty) return;
    isFetchingOvers.value = true;
    errorMessage.value = null;
    try {
      final res = await _apiService.listCricketOvers(teamMatchId: teamMatchId);
      final sorted = List<CricketOverEvent>.from(res)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      cricketOvers.assignAll(sorted);
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

  /// `POST /scoring/cricket/matches/:id/session` — initializes cricket scoring.
  Future<bool> createCricketSession(CreateCricketSessionRequest request) async {
    final sessionId = currentSessionId.value;
    if (sessionId.isEmpty) {
      errorMessage.value = 'No match selected.';
      return false;
    }

    errorMessage.value = null;
    isCreatingCricketSession.value = true;
    // try {
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
    await fetchCricketOvers(sessionId);
    return true;
    // } catch (error) {
    //   errorMessage.value = error.toString();
    //   return false;
    // } finally {
    // }
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

  // Future<void> leaveSession() async {
  //   final sessionId = currentSessionId.value;
  //   if (sessionId.isEmpty) return;

  //   try {
  //     await _socketService.leaveSession(sessionId);
  //     debugPrint('[ScoringController] left session=$sessionId');
  //   } catch (error) {
  //     errorMessage.value = error.toString();
  //   } finally {
  //     currentSessionId.value = '';
  //   }
  // }

  // Future<void> disconnect() async {
  //   await leaveSession();
  //   await _socketService.disconnect();
  //   isConnected.value = false;
  // }

  // @override
  // void onClose() {
  //   _updatesSub?.cancel();
  //   _socketService.dispose();
  //   super.onClose();
  // }

  // void _addOrReplaceEvent(ScoringUpdatePayload event) {
  //   final index = timeline.indexWhere((item) => item.eventId == event.eventId);
  //   if (index >= 0) {
  //     timeline[index] = event;
  //     return;
  //   }
  //   timeline.add(event);
  // }
}
