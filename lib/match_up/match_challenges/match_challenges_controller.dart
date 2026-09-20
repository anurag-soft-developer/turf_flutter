import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';
import '../shared/match_team_filter_controller.dart';

enum MatchChallengesTab { received, sent }

/// Accept/reject mutations + tab state. List fetching is owned by flutter_query.
class MatchChallengesController extends MatchTeamFilterController {
  final MatchmakingService _matchmakingService = MatchmakingService();

  final Rx<MatchChallengesTab> selectedTab = MatchChallengesTab.received.obs;
  final Rxn<String> acceptingMatchId = Rxn<String>();
  final Rxn<String> rejectingMatchId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    applyTabFromArguments();
  }

  void applyTabFromArguments() {
    final tab = enumTabFromArguments(MatchChallengesTab.values);
    if (tab != null) selectedTab.value = tab;
  }

  void switchTab(int index) {
    if (index < 0 || index >= MatchChallengesTab.values.length) return;
    final tab = MatchChallengesTab.values[index];
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
  }

  Future<void> invalidateChallengeQueries() async {
    if (!Get.isRegistered<QueryClient>()) return;
    final client = Get.find<QueryClient>();
    await client.invalidateQueries(queryKey: QueryKeys.matchChallengesPrefix);
    await client.invalidateQueries(queryKey: QueryKeys.myMatchesPrefix);
  }

  Future<void> acceptChallenge(TeamMatchModel match) async {
    final matchId = match.id;
    final actorId = match.toTeamHelper.getId();
    if (matchId == null ||
        matchId.isEmpty ||
        actorId == null ||
        actorId.isEmpty) {
      return;
    }
    if (match.status != TeamMatchStatus.requested) return;
    if (_isMatchExpiredByDeadline(match)) return;

    acceptingMatchId.value = matchId;
    final updated = await _matchmakingService.respond(
      matchId,
      RespondMatchRequest(
        actorTeamId: actorId,
        action: MatchResponseAction.accept,
      ),
    );
    if (updated != null) {
      AppSnackbar.success(
        title: 'Challenge accepted',
        message:
            'You can continue scheduling from match details when available.',
      );
      await invalidateChallengeQueries();
    }
    acceptingMatchId.value = null;
  }

  Future<void> rejectChallenge(TeamMatchModel match) async {
    final matchId = match.id;
    final actorId = match.toTeamHelper.getId();
    if (matchId == null ||
        matchId.isEmpty ||
        actorId == null ||
        actorId.isEmpty) {
      return;
    }
    if (match.status != TeamMatchStatus.requested) return;
    if (_isMatchExpiredByDeadline(match)) return;

    rejectingMatchId.value = matchId;
    final updated = await _matchmakingService.respond(
      matchId,
      RespondMatchRequest(
        actorTeamId: actorId,
        action: MatchResponseAction.reject,
      ),
    );
    if (updated != null) {
      AppSnackbar.success(
        title: 'Challenge rejected',
        message: 'The match request was declined.',
      );
      await invalidateChallengeQueries();
    }
    rejectingMatchId.value = null;
  }

  static bool _isMatchExpiredByDeadline(TeamMatchModel m) {
    final ex = m.expiresAt;
    if (ex == null) return false;
    return DateTime.now().isAfter(ex.toLocal());
  }
}
