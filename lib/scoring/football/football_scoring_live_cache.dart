import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../core/query/query_keys.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../cricket/cricket_scoring_live_cache.dart' show teamMatchStatusFromApi;
import '../shared/scoring_shared_models.dart';
import 'model/football_match_event_model.dart';

/// Whether [data] carries match-level football fields to merge.
bool footballMatchPatchPresent(Map<String, dynamic> data) {
  return data['footballState'] is Map ||
      data['status'] != null ||
      data.containsKey('winnerTeamId') ||
      data['announcedPlayers'] is List;
}

/// Merges scoring-update match fields into [current].
TeamMatchModel patchFootballMatch({
  required TeamMatchModel current,
  Map<String, dynamic>? footballStateJson,
  Object? statusRaw,
  String? winnerTeamId,
  bool clearWinner = false,
  List<dynamic>? announcedPlayersJson,
}) {
  FootballStateModel? nextState = current.footballState;
  if (footballStateJson != null) {
    nextState = FootballStateModel.fromJson(footballStateJson);
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
    cricketState: current.cricketState,
    footballState: nextState,
    createdAt: current.createdAt,
    updatedAt: current.updatedAt,
  );
}

/// Applies match-level fields from a scoring payload [data] map.
TeamMatchModel patchFootballMatchFromData(
  TeamMatchModel current,
  Map<String, dynamic> data,
) {
  return patchFootballMatch(
    current: current,
    footballStateJson: data['footballState'] is Map
        ? (data['footballState'] as Map).cast<String, dynamic>()
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

/// Upserts [event] into a copy of [events], sorted by sequence.
List<FootballMatchEvent> upsertFootballEventInList(
  List<FootballMatchEvent> events,
  FootballMatchEvent event,
) {
  final next = List<FootballMatchEvent>.from(events)
    ..removeWhere((e) {
      if (event.id.isNotEmpty && e.id.isNotEmpty && e.id == event.id) {
        return true;
      }
      return e.sequence == event.sequence;
    })
    ..add(event)
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  return next;
}

/// Removes the event with [eventId] from a copy of [events].
List<FootballMatchEvent> removeFootballEventFromList(
  List<FootballMatchEvent> events,
  String eventId,
) {
  if (eventId.isEmpty) return List<FootballMatchEvent>.from(events);
  return events.where((event) => event.id != eventId).toList();
}

/// Whether [payload] carries a football timeline append or undo.
bool footballEventsPatchPresent(ScoringUpdatePayload payload) {
  if (payload.action == ScoringAction.undoEvent) return true;
  return payload.data['event'] is Map;
}

/// Applies event append/undo from [payload] onto [currentEvents].
///
/// Returns `null` when the action is not event-related.
List<FootballMatchEvent>? patchFootballEventsFromPayload(
  List<FootballMatchEvent> currentEvents,
  ScoringUpdatePayload payload,
) {
  if (!footballEventsPatchPresent(payload)) return null;

  final data = payload.data;
  final eventJson = data['event'];
  if (eventJson is Map) {
    final event =
        FootballMatchEvent.fromJson(eventJson.cast<String, dynamic>());
    return upsertFootballEventInList(currentEvents, event);
  }
  if (payload.action == ScoringAction.undoEvent) {
    final eventId = data['eventId']?.toString() ?? '';
    if (eventId.isNotEmpty) {
      return removeFootballEventFromList(currentEvents, eventId);
    }
  }
  return List<FootballMatchEvent>.from(currentEvents);
}

/// Patches flutter_query football caches from a live [ScoringUpdatePayload].
///
/// Used by challenge detail (spectator) and the scoreboard remote path.
void applyFootballScoringUpdateToCache(
  QueryClient client,
  ScoringUpdatePayload payload, {
  String? expectedMatchId,
}) {
  if (payload.sport != ScoringSport.football) return;

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
    debugPrint('applyFootballScoringUpdateToCache failed: $e\n$st');
  }
}

void _applyToCache(QueryClient client, ScoringUpdatePayload payload, String id) {
  final session = client.getQueryData<TeamMatchModel>(
    QueryKeys.footballSession(id),
  );
  final detail = client.getQueryData<TeamMatchModel>(
    QueryKeys.matchChallengeDetail(id),
  );
  final base = session ?? detail;

  final eventRelated = footballEventsPatchPresent(payload);

  if (base == null) {
    unawaited(
      client.invalidateQueries(queryKey: QueryKeys.footballSession(id)),
    );
    unawaited(
      client.invalidateQueries(queryKey: QueryKeys.matchChallengeDetail(id)),
    );
    if (eventRelated) {
      unawaited(
        client.invalidateQueries(queryKey: QueryKeys.footballEvents(id)),
      );
    }
    return;
  }

  final data = payload.data;
  var nextMatch = base;
  if (footballMatchPatchPresent(data)) {
    nextMatch = patchFootballMatchFromData(base, data);
  }

  List<FootballMatchEvent>? nextEvents;
  var includeEvents = false;
  if (eventRelated) {
    final currentEvents = client.getQueryData<List<FootballMatchEvent>>(
      QueryKeys.footballEvents(id),
    );
    if (currentEvents == null) {
      unawaited(
        client.invalidateQueries(queryKey: QueryKeys.footballEvents(id)),
      );
    } else {
      includeEvents = true;
      nextEvents = patchFootballEventsFromPayload(currentEvents, payload);
    }
  }

  client.setQueryData<TeamMatchModel, Object>(
    QueryKeys.footballSession(id),
    (_) => nextMatch,
  );
  client.setQueryData<TeamMatchModel, Object>(
    QueryKeys.matchChallengeDetail(id),
    (_) => nextMatch,
  );
  if (includeEvents && nextEvents != null) {
    client.setQueryData<List<FootballMatchEvent>, Object>(
      QueryKeys.footballEvents(id),
      (_) => nextEvents!,
    );
  }
}
