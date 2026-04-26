import 'package:get/get.dart';

import '../../components/shared/app_segmented_tabs/segmented_tab_cache_controller.dart';
import '../../core/utils/app_snackbar.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/team_service.dart';
import '../matchmaking_service.dart';
import '../model/team_match_model.dart';

enum MatchChallengesTab { received, sent, completed, upcoming, archive }

/// Lists match requests; filter by one team or merge all of the user’s teams.
class MatchChallengesController extends GetxController
    with SegmentedTabCacheController<MatchChallengesTab, TeamMatchModel> {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TeamService _teamService = TeamService();

  static const int _historyPageLimit = 20;

  final Rx<MatchChallengesTab> selectedTab = MatchChallengesTab.received.obs;
  final RxBool isLoadingMemberships = true.obs;
  final Rxn<String> acceptingMatchId = Rxn<String>();
  final Rxn<String> rejectingMatchId = Rxn<String>();

  final RxList<TeamMemberModel> memberships = <TeamMemberModel>[].obs;
  final RxBool filterAllTeams = true.obs;
  final Rxn<TeamMemberFieldInstance> selectedMembershipTeam =
      Rxn<TeamMemberFieldInstance>();

  @override
  List<MatchChallengesTab> get tabKeys => MatchChallengesTab.values;

  List<TeamMemberFieldInstance> get myTeams {
    final list = <TeamMemberFieldInstance>[];
    for (final m in memberships) {
      final t = m.team;
      if (t is TeamMemberFieldInstance && t.id != null && t.id!.isNotEmpty) {
        list.add(t);
      }
    }
    final seen = <String>{};
    return list.where((t) => seen.add(t.id!)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await loadMemberships();
    await loadSelectedTab();
  }

  Future<void> loadMemberships() async {
    isLoadingMemberships.value = true;
    try {
      final res = await _teamService.memberService.myMemberships(
        const MyTeamMembershipsFilterQuery(
          status: TeamMemberStatus.active,
          limit: 50,
        ),
      );
      memberships.assignAll(res?.data ?? []);
      if (!filterAllTeams.value) {
        final sel = selectedMembershipTeam.value;
        if (sel != null && !myTeams.any((t) => t.id == sel.id)) {
          selectedMembershipTeam.value = myTeams.isNotEmpty
              ? myTeams.first
              : null;
        }
      }
    } finally {
      isLoadingMemberships.value = false;
    }
  }

  void selectTeamForFilter(TeamMemberFieldInstance team) {
    filterAllTeams.value = false;
    selectedMembershipTeam.value = team;
    refreshAllTabs();
  }

  void selectAllTeamsFilter() {
    filterAllTeams.value = true;
    refreshAllTabs();
  }

  Future<void> loadSelectedTab() async {
    if (myTeams.isEmpty) {
      _clearAllTabStates();
      return;
    }
    await ensureTabLoaded(selectedTab.value);
  }

  void _clearAllTabStates() {
    for (final tab in tabKeys) {
      setTabState(tab, const SegmentedTabDataState<TeamMatchModel>());
    }
  }

  @override
  Future<List<TeamMatchModel>> fetchTabItems(MatchChallengesTab tab) async {
    switch (tab) {
      case MatchChallengesTab.received:
      case MatchChallengesTab.sent:
        return _fetchNegotiationItems(tab);
      case MatchChallengesTab.completed:
        return _fetchCompletedItems();
      case MatchChallengesTab.upcoming:
        return _fetchUpcomingItems();
      case MatchChallengesTab.archive:
        return _fetchArchiveItems();
    }
  }

  /// Inbox / outbox: active challenge flow only ([requested], [accepted], [negotiating]).
  static bool _isPreMatchInbox(TeamMatchModel m) {
    if (m.status == TeamMatchStatus.requested) {
      if (_isMatchExpiredByDeadline(m)) return false;
    }
    return m.status == TeamMatchStatus.requested ||
        m.status == TeamMatchStatus.accepted ||
        m.status == TeamMatchStatus.negotiating;
  }

  Future<List<TeamMatchModel>> _fetchNegotiationItems(
    MatchChallengesTab tab,
  ) async {
    final type = tab == MatchChallengesTab.received
        ? NegotiationListType.incoming
        : NegotiationListType.outgoing;

    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) {
        return <TeamMatchModel>[];
      }
      final res = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(teamId: tid, type: type, limit: 50),
      );
      final items = (res?.data ?? []).where(_isPreMatchInbox).toList()
        ..sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      return items;
    }

    final merged = <String, TeamMatchModel>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      final res = await _matchmakingService.listRequests(
        ListNegotiationsFilterQuery(teamId: tid, type: type, limit: 50),
      );
      for (final m in res?.data ?? []) {
        if (!_isPreMatchInbox(m)) continue;
        final mid = m.id;
        if (mid != null && mid.isNotEmpty) merged[mid] = m;
      }
    }
    return merged.values.toList()..sort((a, b) {
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
  }

  /// Finished results: [TeamMatchStatus.completed] and [TeamMatchStatus.draw].
  Future<List<TeamMatchModel>> _fetchCompletedForTeam(String teamId) async {
    final result = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.completed,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final drawResult = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.draw,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final matches = <TeamMatchModel>[
      ...(result?.data ?? []),
      ...(drawResult?.data ?? []),
    ];
    matches.sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(2000),
      ),
    );
    return matches;
  }

  Future<List<TeamMatchModel>> _fetchCompletedItems() async {
    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) return <TeamMatchModel>[];
      return _fetchCompletedForTeam(tid);
    }
    final merged = <String, TeamMatchModel>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      final list = await _fetchCompletedForTeam(tid);
      for (final m in list) {
        final mid = m.id;
        if (mid != null && mid.isNotEmpty) merged[mid] = m;
      }
    }
    return merged.values.toList()..sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(2000),
      ),
    );
  }

  /// Scheduled or in progress (excludes [accepted] / [negotiating] — those stay
  /// in Received/Sent as pre-match).
  Future<List<TeamMatchModel>> _fetchUpcomingForTeam(String teamId) async {
    final scheduled = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.scheduleFinalized,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final live = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.ongoing,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final matches = <TeamMatchModel>[
      ...(scheduled?.data ?? []),
      ...(live?.data ?? []),
    ];
    matches.sort(
      (a, b) => (a.createdAt ?? DateTime(2099)).compareTo(
        b.createdAt ?? DateTime(2099),
      ),
    );
    return matches;
  }

  Future<List<TeamMatchModel>> _fetchUpcomingItems() async {
    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) return <TeamMatchModel>[];
      return _fetchUpcomingForTeam(tid);
    }
    final merged = <String, TeamMatchModel>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      final list = await _fetchUpcomingForTeam(tid);
      for (final m in list) {
        final mid = m.id;
        if (mid != null && mid.isNotEmpty) merged[mid] = m;
      }
    }
    return merged.values.toList()..sort(
      (a, b) => (a.createdAt ?? DateTime(2099)).compareTo(
        b.createdAt ?? DateTime(2099),
      ),
    );
  }

  Future<List<TeamMatchModel>> _fetchArchiveForTeam(String teamId) async {
    final rejected = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.rejected,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final cancelled = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.cancelled,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final expired = await _matchmakingService.listRequests(
      ListNegotiationsFilterQuery(
        teamId: teamId,
        type: NegotiationListType.all,
        status: TeamMatchStatus.expired,
        page: 1,
        limit: _historyPageLimit,
      ),
    );
    final matches = <TeamMatchModel>[
      ...(rejected?.data ?? []),
      ...(cancelled?.data ?? []),
      ...(expired?.data ?? []),
    ];
    matches.sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(2000),
      ),
    );
    return matches;
  }

  Future<List<TeamMatchModel>> _fetchArchiveItems() async {
    if (!filterAllTeams.value) {
      final tid = selectedMembershipTeam.value?.id;
      if (tid == null || tid.isEmpty) return <TeamMatchModel>[];
      return _fetchArchiveForTeam(tid);
    }
    final merged = <String, TeamMatchModel>{};
    for (final t in myTeams) {
      final tid = t.id;
      if (tid == null || tid.isEmpty) continue;
      final list = await _fetchArchiveForTeam(tid);
      for (final m in list) {
        final mid = m.id;
        if (mid != null && mid.isNotEmpty) merged[mid] = m;
      }
    }
    return merged.values.toList()..sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(2000),
      ),
    );
  }

  @override
  String mapFetchError(Object error) => 'Failed to load';

  /// Clears tab cache and refetches a single tab (e.g. retry after error).
  Future<void> resetAndRefetch(MatchChallengesTab tab) async {
    setTabState(tab, const SegmentedTabDataState<TeamMatchModel>());
    await ensureTabLoaded(tab, force: true);
  }

  /// Updates a single match in the **selected** tab only. Replaces the row, removes
  /// it if it no longer belongs, or no-ops if this tab was never loaded. Other
  /// tab caches are unchanged. No-op if [updated.id] is null.
  void applyMatchUpdateFromDetail(TeamMatchModel updated) {
    final id = updated.id;
    if (id == null || id.isEmpty) return;

    bool matchInvolvesCurrentFilter(TeamMatchModel m) {
      final fromId = m.fromTeamHelper.getId();
      final toId = m.toTeamHelper.getId();
      if (!filterAllTeams.value) {
        final sel = selectedMembershipTeam.value?.id;
        if (sel == null) return false;
        return sel == fromId || sel == toId;
      }
      for (final t in myTeams) {
        final tid = t.id;
        if (tid != null && (tid == fromId || tid == toId)) return true;
      }
      return false;
    }

    bool matchBelongsInReceived(TeamMatchModel m) {
      if (!_isPreMatchInbox(m)) return false;
      final toId = m.toTeamHelper.getId();
      if (toId == null) return false;
      if (!filterAllTeams.value) {
        return selectedMembershipTeam.value?.id == toId;
      }
      return myTeams.any((t) => t.id == toId);
    }

    bool matchBelongsInSent(TeamMatchModel m) {
      if (!_isPreMatchInbox(m)) return false;
      final fromId = m.fromTeamHelper.getId();
      if (fromId == null) return false;
      if (!filterAllTeams.value) {
        return selectedMembershipTeam.value?.id == fromId;
      }
      return myTeams.any((t) => t.id == fromId);
    }

    bool matchBelongsInCompleted(TeamMatchModel m) {
      if (m.status != TeamMatchStatus.completed &&
          m.status != TeamMatchStatus.draw) {
        return false;
      }
      return matchInvolvesCurrentFilter(m);
    }

    bool matchBelongsInUpcoming(TeamMatchModel m) {
      if (m.status != TeamMatchStatus.scheduleFinalized &&
          m.status != TeamMatchStatus.ongoing) {
        return false;
      }
      return matchInvolvesCurrentFilter(m);
    }

    bool matchBelongsInArchive(TeamMatchModel m) {
      if (m.status != TeamMatchStatus.rejected &&
          m.status != TeamMatchStatus.cancelled &&
          m.status != TeamMatchStatus.expired) {
        return false;
      }
      return matchInvolvesCurrentFilter(m);
    }

    void sortItemsForTab(MatchChallengesTab tab, List<TeamMatchModel> items) {
      switch (tab) {
        case MatchChallengesTab.received:
        case MatchChallengesTab.sent:
          items.sort((a, b) {
            final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
        case MatchChallengesTab.completed:
        case MatchChallengesTab.archive:
          items.sort(
            (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000)).compareTo(
              a.updatedAt ?? a.createdAt ?? DateTime(2000),
            ),
          );
        case MatchChallengesTab.upcoming:
          items.sort(
            (a, b) => (a.createdAt ?? DateTime(2099)).compareTo(
              b.createdAt ?? DateTime(2099),
            ),
          );
      }
    }

    final tab = selectedTab.value;
    final state = tabStateFor(tab);
    if (!state.hasInitialized) return;

    final without = state.items.where((m) => m.id != id).toList();
    final shouldInclude = switch (tab) {
      MatchChallengesTab.received => matchBelongsInReceived(updated),
      MatchChallengesTab.sent => matchBelongsInSent(updated),
      MatchChallengesTab.completed => matchBelongsInCompleted(updated),
      MatchChallengesTab.upcoming => matchBelongsInUpcoming(updated),
      MatchChallengesTab.archive => matchBelongsInArchive(updated),
    };
    final items = shouldInclude ? [...without, updated] : without;
    sortItemsForTab(tab, items);
    setTabState(tab, state.copyWith(items: items, clearError: true));
  }

  Future<void> switchTab(int index) async {
    if (index < 0 || index >= MatchChallengesTab.values.length) return;
    final tab = MatchChallengesTab.values[index];
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    await ensureTabLoaded(tab);
  }

  Future<void> refreshCurrentTab() async {
    await ensureTabLoaded(selectedTab.value, force: true);
  }

  Future<void> refreshAllTabs() async {
    _clearAllTabStates();
    await loadSelectedTab();
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
    try {
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
        applyMatchUpdateFromDetail(updated);
      } else {
        AppSnackbar.error(
          title: 'Could not accept',
          message: 'Try again later.',
        );
      }
    } finally {
      acceptingMatchId.value = null;
    }
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
    try {
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
        applyMatchUpdateFromDetail(updated);
      } else {
        AppSnackbar.error(
          title: 'Could not reject',
          message: 'Try again later.',
        );
      }
    } finally {
      rejectingMatchId.value = null;
    }
  }

  static bool _isMatchExpiredByDeadline(TeamMatchModel m) {
    final ex = m.expiresAt;
    if (ex == null) return false;
    return DateTime.now().isAfter(ex.toLocal());
  }
}
