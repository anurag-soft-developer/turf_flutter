import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../core/query/query_keys.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../shared/scoring_shared_models.dart';
import 'model/cricket_ball_event_model.dart';

/// Whether [data] carries match-level cricket fields to merge.
bool cricketMatchPatchPresent(Map<String, dynamic> data) {
  return data['cricketState'] is Map ||
      data['status'] != null ||
      data.containsKey('winnerTeamId') ||
      data['announcedPlayers'] is List;
}

/// Merges scoring-update match fields into [current].
TeamMatchModel patchCricketMatch({
  required TeamMatchModel current,
  Map<String, dynamic>? cricketStateJson,
  Object? statusRaw,
  String? winnerTeamId,
  bool clearWinner = false,
  List<dynamic>? announcedPlayersJson,
}) {
  CricketStateModel? nextState = current.cricketState;
  if (cricketStateJson != null) {
    nextState = CricketStateModel.fromJson(cricketStateJson);
  }

  final nextStatus = teamMatchStatusFromApi(statusRaw) ?? current.status;

  dynamic nextWinner = current.winnerTeam;
  if (clearWinner) {
    nextWinner = null;
  } else if (winnerTeamId != null && winnerTeamId.isNotEmpty) {
    nextWinner = winnerTeamId;
  }

  List<AnnouncedPlayerModel> nextAnnounced = current.announcedPlayers;
  if (announcedPlayersJson != null) {
    nextAnnounced = announcedPlayersJson
        .whereType<Map>()
        .map((e) => AnnouncedPlayerModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  return TeamMatchModel(
    id: current.id,
    source: current.source,
    fromTeam: current.fromTeam,
    toTeam: current.toTeam,
    sportType: current.sportType,
    status: nextStatus,
    statusUpdatedBy: current.statusUpdatedBy,
    statusUpdatedAt: current.statusUpdatedAt,
    proposedSlots: current.proposedSlots,
    proposedTurfs: current.proposedTurfs,
    selectedSlotProposalId: current.selectedSlotProposalId,
    selectedTurfProposalId: current.selectedTurfProposalId,
    winnerTeam: nextWinner,
    notes: current.notes,
    turfBookingId: current.turfBookingId,
    expiresAt: current.expiresAt,
    closedAt: current.closedAt,
    announcedPlayers: nextAnnounced,
    cricketState: nextState,
    footballState: current.footballState,
    createdAt: current.createdAt,
    updatedAt: current.updatedAt,
  );
}

/// Applies match-level fields from a scoring payload [data] map.
TeamMatchModel patchCricketMatchFromData(
  TeamMatchModel current,
  Map<String, dynamic> data,
) {
  return patchCricketMatch(
    current: current,
    cricketStateJson: data['cricketState'] is Map
        ? (data['cricketState'] as Map).cast<String, dynamic>()
        : null,
    statusRaw: data['status'],
    winnerTeamId: data.containsKey('winnerTeamId')
        ? data['winnerTeamId']?.toString()
        : null,
    clearWinner:
        data.containsKey('winnerTeamId') && data['winnerTeamId'] == null,
    announcedPlayersJson:
        data['announcedPlayers'] is List ? (data['announcedPlayers'] as List) : null,
  );
}

/// Upserts [over] into a copy of [overs], sorted by sequence.
List<CricketOverEvent> upsertCricketOverInList(
  List<CricketOverEvent> overs,
  CricketOverEvent over,
) {
  final next = List<CricketOverEvent>.from(overs)
    ..removeWhere((o) {
      if (over.id.isNotEmpty && o.id.isNotEmpty && o.id == over.id) {
        return true;
      }
      return o.innings == over.innings &&
          o.overAfter == over.overAfter &&
          o.sequence == over.sequence;
    })
    ..add(over)
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  return next;
}

/// Removes the over with [overId] from a copy of [overs].
List<CricketOverEvent> removeCricketOverFromList(
  List<CricketOverEvent> overs,
  String overId,
) {
  if (overId.isEmpty) return List<CricketOverEvent>.from(overs);
  return overs.where((over) => over.id != overId).toList();
}

/// Applies ball append/undo from [payload] onto [currentOvers].
///
/// Returns `null` when the action is not ball-related.
List<CricketOverEvent>? patchCricketOversFromPayload(
  List<CricketOverEvent> currentOvers,
  ScoringUpdatePayload payload,
) {
  final ballRelated = payload.action == ScoringAction.appendBall ||
      payload.action == ScoringAction.undoBall;
  if (!ballRelated) return null;

  final data = payload.data;
  final overJson = data['over'];
  if (overJson is Map) {
    final over = CricketOverEvent.fromJson(overJson.cast<String, dynamic>());
    return upsertCricketOverInList(currentOvers, over);
  }
  if (payload.action == ScoringAction.undoBall) {
    final overId = data['overId']?.toString() ?? '';
    if (overId.isNotEmpty) {
      return removeCricketOverFromList(currentOvers, overId);
    }
  }
  return List<CricketOverEvent>.from(currentOvers);
}

TeamMatchStatus? teamMatchStatusFromApi(Object? raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return null;
  return switch (value) {
    'requested' => TeamMatchStatus.requested,
    'accepted' => TeamMatchStatus.accepted,
    'negotiating' => TeamMatchStatus.negotiating,
    'schedule_finalized' => TeamMatchStatus.scheduleFinalized,
    'rejected' => TeamMatchStatus.rejected,
    'expired' => TeamMatchStatus.expired,
    'cancelled' => TeamMatchStatus.cancelled,
    'ongoing' => TeamMatchStatus.ongoing,
    'completed' => TeamMatchStatus.completed,
    'draw' => TeamMatchStatus.draw,
    'abandoned' => TeamMatchStatus.abandoned,
    _ => null,
  };
}

/// Patches flutter_query cricket caches from a live [ScoringUpdatePayload].
///
/// Used by challenge detail (spectator) and the scoreboard remote path.
void applyCricketScoringUpdateToCache(
  QueryClient client,
  ScoringUpdatePayload payload, {
  String? expectedMatchId,
}) {
  if (payload.sport != ScoringSport.cricket) return;

  final id = payload.teamMatchId.trim();
  if (id.isEmpty) return;
  if (expectedMatchId != null &&
      expectedMatchId.isNotEmpty &&
      expectedMatchId != id) {
    return;
  }

  try {
    _applyToCache(client, payload, id);
  } catch (e, st) {
    debugPrint('applyCricketScoringUpdateToCache failed: $e\n$st');
  }
}

void _applyToCache(QueryClient client, ScoringUpdatePayload payload, String id) {
  final session = client.getQueryData<TeamMatchModel>(
    QueryKeys.cricketSession(id),
  );
  final detail = client.getQueryData<TeamMatchModel>(
    QueryKeys.matchChallengeDetail(id),
  );
  final base = session ?? detail;

  final ballRelated = payload.action == ScoringAction.appendBall ||
      payload.action == ScoringAction.undoBall;

  if (base == null) {
    unawaited(
      client.invalidateQueries(queryKey: QueryKeys.cricketSession(id)),
    );
    unawaited(
      client.invalidateQueries(queryKey: QueryKeys.matchChallengeDetail(id)),
    );
    if (ballRelated) {
      unawaited(
        client.invalidateQueries(queryKey: QueryKeys.cricketOvers(id)),
      );
    }
    return;
  }

  final data = payload.data;
  var nextMatch = base;
  if (cricketMatchPatchPresent(data)) {
    nextMatch = patchCricketMatchFromData(base, data);
  }

  List<CricketOverEvent>? nextOvers;
  var includeOvers = false;
  if (ballRelated) {
    final currentOvers =
        client.getQueryData<List<CricketOverEvent>>(QueryKeys.cricketOvers(id));
    if (currentOvers == null) {
      unawaited(
        client.invalidateQueries(queryKey: QueryKeys.cricketOvers(id)),
      );
    } else {
      includeOvers = true;
      nextOvers = patchCricketOversFromPayload(currentOvers, payload);
    }
  }

  client.setQueryData<TeamMatchModel, Object>(
    QueryKeys.cricketSession(id),
    (_) => nextMatch,
  );
  client.setQueryData<TeamMatchModel, Object>(
    QueryKeys.matchChallengeDetail(id),
    (_) => nextMatch,
  );
  if (includeOvers && nextOvers != null) {
    client.setQueryData<List<CricketOverEvent>, Object>(
      QueryKeys.cricketOvers(id),
      (_) => nextOvers!,
    );
  }
}
