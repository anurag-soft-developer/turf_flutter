import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/announced_players/announced_players_service.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/members/team_member_service.dart';
import 'util/announced_player_roles_helpers.dart';
import 'guest_sheets.dart';

class GuestRowVm {
  const GuestRowVm({
    required this.participantId,
    required this.name,
    this.avatar,
    required this.role,
  });

  final String participantId;
  final String name;
  final String? avatar;
  final AnnouncedPlayerRole role;
}

class ManageAnnouncedPlayersController extends GetxController {
  ManageAnnouncedPlayersController({
    required TeamMatchModel match,
    required this.actorTeamId,
    required this.onSaved,
  }) : currentMatch = match.obs;

  final String actorTeamId;
  final void Function(TeamMatchModel updated) onSaved;

  final AnnouncedPlayersService _announcedApi = AnnouncedPlayersService();
  final TeamMemberService _memberApi = TeamMemberService();

  final Rx<TeamMatchModel> currentMatch;
  final RxSet<String> selectedUserIds = <String>{}.obs;
  final RxnString captainParticipantId = RxnString();
  final RxnString viceCaptainParticipantId = RxnString();
  final RxSet<String> substituteParticipantIds = <String>{}.obs;

  /// Participants currently mid-mutation (row-level busy).
  final RxSet<String> busyParticipantIds = <String>{}.obs;
  final RxBool syncing = false.obs;

  final RxList<TeamMemberModel> roster = <TeamMemberModel>[].obs;
  final RxBool loadingRoster = true.obs;
  final RxnString rosterError = RxnString();

  /// Bumped on each mutation start; open-sync ignores results if mutations ran.
  int _mutationEpoch = 0;

  String? get matchId => currentMatch.value.id;

  bool get isUnranked => currentMatch.value.isUnranked;

  List<AnnouncedPlayerModel> get announcedForTeam => currentMatch
      .value.announcedPlayers
      .where((p) => p.teamIdHelper.getId() == actorTeamId)
      .toList();

  List<AnnouncedPlayerModel> get rosterAnnounced =>
      announcedForTeam.where((p) => !p.isGuest).toList();

  List<AnnouncedPlayerModel> get serverGuests =>
      announcedForTeam.where((p) => p.isGuest).toList();

  List<GuestRowVm> get visibleGuestRows {
    final rows = <GuestRowVm>[];
    for (final g in serverGuests) {
      final pid = g.participantId;
      if (pid == null) continue;
      rows.add(
        GuestRowVm(
          participantId: pid,
          name: g.name,
          avatar: g.avatar,
          role: g.role,
        ),
      );
    }
    return rows;
  }

  Set<String> get rosterIds => {
        for (final m in roster)
          if (m.userHelper.getId() != null) m.userHelper.getId()!,
      };

  List<AnnouncedPlayerModel> get orphans => rosterAnnounced.where((p) {
        final uid = p.userIdHelper.getId();
        if (uid == null) return true;
        return !rosterIds.contains(uid);
      }).toList();

  String get teamName {
    final fromId = currentMatch.value.fromTeamHelper.getId();
    final toId = currentMatch.value.toTeamHelper.getId();
    if (fromId != null && fromId == actorTeamId) {
      return currentMatch.value.fromTeamHelper.getDisplayName();
    }
    if (toId != null && toId == actorTeamId) {
      return currentMatch.value.toTeamHelper.getDisplayName();
    }
    return 'Announced squad';
  }

  String get teamLogo {
    final fromId = currentMatch.value.fromTeamHelper.getId();
    final toId = currentMatch.value.toTeamHelper.getId();
    if (fromId != null && fromId == actorTeamId) {
      return currentMatch.value.fromTeamHelper.getSubsetModel()?.logo ?? '';
    }
    if (toId != null && toId == actorTeamId) {
      return currentMatch.value.toTeamHelper.getSubsetModel()?.logo ?? '';
    }
    return '';
  }

  /// Block list interactions only while roster/squad sync is loading.
  bool get interactionsLocked => loadingRoster.value || syncing.value;

  @override
  void onInit() {
    super.onInit();
    _mirrorSelectionFromMatch();
    _syncMetaFromMatch();
    Future.wait([loadRoster(), syncAnnouncedFromServer()]);
  }

  void _mirrorSelectionFromMatch() {
    selectedUserIds
      ..clear()
      ..addAll({
        for (final p in rosterAnnounced)
          if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
      });
  }

  void _syncMetaFromMatch() {
    String? serverCaptain;
    String? serverVice;
    final subs = <String>{};
    for (final p in announcedForTeam) {
      final pid = p.participantId;
      if (pid == null) continue;
      if (p.isCaption) serverCaptain = pid;
      if (p.isWiseCaption) serverVice = pid;
      if (p.isSubstitute) subs.add(pid);
    }
    captainParticipantId.value = serverCaptain;
    viceCaptainParticipantId.value = serverVice;
    substituteParticipantIds
      ..clear()
      ..addAll(subs);
  }

  Future<void> loadRoster() async {
    loadingRoster.value = true;
    rosterError.value = null;
    try {
      final page = await _memberApi.listForTeam(
        actorTeamId,
        const TeamMemberRosterFilterQuery(
          status: TeamMemberStatus.active,
          limit: 100,
        ),
      );
      if (isClosed) return;
      final data = page?.data ?? const <TeamMemberModel>[];
      roster.assignAll(data);
      if (data.isEmpty && orphans.isEmpty) {
        rosterError.value = 'No active members found for this team.';
      }
    } catch (e) {
      if (isClosed) return;
      rosterError.value = e.toString();
    } finally {
      if (!isClosed) loadingRoster.value = false;
    }
  }

  /// Authoritative team squad from GET; merges into [currentMatch] + [onSaved].
  Future<void> syncAnnouncedFromServer({bool invalidateQuery = false}) async {
    final mid = matchId;
    if (mid == null || mid.isEmpty) return;
    final epochAtStart = _mutationEpoch;
    syncing.value = true;
    try {
      final latestSlice = await _announcedApi.listForTeam(
        teamMatchId: mid,
        actorTeamId: actorTeamId,
      );
      if (isClosed) return;
      // A mutation started while this GET was in flight — keep local state.
      if (_mutationEpoch != epochAtStart) return;
      _mergeTeamSlice(latestSlice, invalidateQuery: invalidateQuery);
    } finally {
      if (!isClosed) syncing.value = false;
    }
  }

  void _mergeTeamSlice(
    List<AnnouncedPlayerModel> latestSlice, {
    bool invalidateQuery = true,
  }) {
    final match = currentMatch.value;
    final kept = match.announcedPlayers
        .where((p) => p.teamIdHelper.getId() != actorTeamId)
        .toList();
    final merged = match.copyWith(
      announcedPlayers: [...kept, ...latestSlice],
    );
    currentMatch.value = merged;
    _mirrorSelectionFromMatch();
    _syncMetaFromMatch();
    onSaved(merged);
    final mid = matchId;
    if (invalidateQuery &&
        mid != null &&
        mid.isNotEmpty &&
        Get.isRegistered<QueryClient>()) {
      Get.find<QueryClient>().invalidateQueries(
        queryKey: QueryKeys.matchChallengeDetail(mid),
      );
    }
  }

  /// Optimistic mutate with surgical [revert] on failure (no full-match restore).
  Future<void> runMutation({
    required Set<String> busyIds,
    required void Function() optimistic,
    required void Function() revert,
    required Future<List<AnnouncedPlayerModel>> Function() call,
  }) async {
    if (isClosed) return;
    if (busyIds.any(busyParticipantIds.contains)) return;

    _mutationEpoch++;
    busyParticipantIds.addAll(busyIds);
    try {
      optimistic();
      final slice = await call();
      if (isClosed) return;
      _mergeTeamSlice(slice);
    } catch (_) {
      if (!isClosed) revert();
    } finally {
      if (!isClosed) {
        busyParticipantIds.removeAll(busyIds);
      }
    }
  }

  TeamMemberModel? findRosterMember(String userId) {
    for (final m in roster) {
      if (m.userHelper.getId() == userId) return m;
    }
    return null;
  }

  bool isSquadParticipant(String participantId) {
    if (selectedUserIds.contains(participantId)) return true;
    return serverGuests.any((g) => g.participantId == participantId);
  }

  bool isBusy(String participantId) =>
      busyParticipantIds.contains(participantId);

  /// True when [userId] is already on the opponent's announced squad.
  bool isAnnouncedForOpponent(String userId) {
    for (final p in currentMatch.value.announcedPlayers) {
      if (p.teamIdHelper.getId() == actorTeamId) continue;
      if (p.userIdHelper.getId() == userId) return true;
    }
    return false;
  }

  AnnouncedPlayerRole roleForUserId(String userId) {
    for (final p in rosterAnnounced) {
      if (p.userIdHelper.getId() == userId) return p.role;
    }
    return defaultAnnouncedRoleForSport(currentMatch.value.sportType);
  }

  void _removeActorPlayerByUserId(String userId) {
    selectedUserIds.remove(userId);
    if (captainParticipantId.value == userId) {
      captainParticipantId.value = null;
    }
    if (viceCaptainParticipantId.value == userId) {
      viceCaptainParticipantId.value = null;
    }
    substituteParticipantIds.remove(userId);
    final match = currentMatch.value;
    currentMatch.value = match.copyWith(
      announcedPlayers: match.announcedPlayers
          .where(
            (p) =>
                !(p.teamIdHelper.getId() == actorTeamId &&
                    p.userIdHelper.getId() == userId),
          )
          .toList(),
    );
  }

  void _removeActorPlayerByParticipantId(String participantId) {
    if (captainParticipantId.value == participantId) {
      captainParticipantId.value = null;
    }
    if (viceCaptainParticipantId.value == participantId) {
      viceCaptainParticipantId.value = null;
    }
    substituteParticipantIds.remove(participantId);
    final match = currentMatch.value;
    currentMatch.value = match.copyWith(
      announcedPlayers: match.announcedPlayers.where((p) {
        if (p.teamIdHelper.getId() != actorTeamId) return true;
        return p.participantId != participantId;
      }).toList(),
    );
  }

  void _applyMetaFlagsToMatch({
    required String? captainId,
    required String? viceCaptainId,
    required Set<String> substituteIds,
  }) {
    final match = currentMatch.value;
    final updated = match.announcedPlayers.map((p) {
      if (p.teamIdHelper.getId() != actorTeamId) return p;
      final pid = p.participantId;
      if (pid == null) return p;
      return p.copyWith(
        isCaption: captainId == pid,
        isWiseCaption: viceCaptainId == pid,
        isSubstitute: substituteIds.contains(pid),
      );
    }).toList();
    currentMatch.value = match.copyWith(announcedPlayers: updated);
  }

  List<AnnouncedPlayerUpdatePayload> _buildMetaPatches(
    List<AnnouncedPlayerModel> slice, {
    required String? captainId,
    required String? viceCaptainId,
    required Set<String> substituteIds,
  }) {
    final updates = <AnnouncedPlayerUpdatePayload>[];
    for (final p in slice) {
      final pid = p.participantId;
      if (pid == null) continue;
      final uid = p.userIdHelper.getId();
      final wantCaptain = captainId == pid;
      final wantVice = viceCaptainId == pid;
      final wantSub = substituteIds.contains(pid);
      if (wantCaptain != p.isCaption ||
          wantVice != p.isWiseCaption ||
          wantSub != p.isSubstitute) {
        updates.add(
          AnnouncedPlayerUpdatePayload(
            userId: uid,
            guestId: uid == null ? p.guestId : null,
            isCaption: wantCaptain,
            isWiseCaption: wantVice,
            isSubstitute: wantSub,
          ),
        );
      }
    }
    return updates;
  }

  Future<void> _patchMeta({
    required Set<String> busyIds,
    required String? captainId,
    required String? viceCaptainId,
    required Set<String> substituteIds,
  }) async {
    final mid = matchId;
    if (mid == null || mid.isEmpty) return;

    final baseline = List<AnnouncedPlayerModel>.from(announcedForTeam);
    final patches = _buildMetaPatches(
      baseline,
      captainId: captainId,
      viceCaptainId: viceCaptainId,
      substituteIds: substituteIds,
    );
    if (patches.isEmpty) return;

    final prevCap = captainParticipantId.value;
    final prevVice = viceCaptainParticipantId.value;
    final prevSubs = substituteParticipantIds.toSet();

    await runMutation(
      busyIds: busyIds,
      optimistic: () {
        captainParticipantId.value = captainId;
        viceCaptainParticipantId.value = viceCaptainId;
        substituteParticipantIds
          ..clear()
          ..addAll(substituteIds);
        _applyMetaFlagsToMatch(
          captainId: captainId,
          viceCaptainId: viceCaptainId,
          substituteIds: substituteIds,
        );
      },
      revert: () {
        captainParticipantId.value = prevCap;
        viceCaptainParticipantId.value = prevVice;
        substituteParticipantIds
          ..clear()
          ..addAll(prevSubs);
        _applyMetaFlagsToMatch(
          captainId: prevCap,
          viceCaptainId: prevVice,
          substituteIds: prevSubs,
        );
      },
      call: () => _announcedApi.updateAnnouncedPlayers(
        teamMatchId: mid,
        actorTeamId: actorTeamId,
        updates: patches,
      ),
    );
  }

  Future<void> toggleMember(String userId) async {
    if (interactionsLocked || isBusy(userId)) return;
    final mid = matchId;
    if (mid == null || mid.isEmpty) return;

    if (selectedUserIds.contains(userId)) {
      AnnouncedPlayerModel? removed;
      for (final p in rosterAnnounced) {
        if (p.userIdHelper.getId() == userId) {
          removed = p;
          break;
        }
      }
      final prevCap = captainParticipantId.value;
      final prevVice = viceCaptainParticipantId.value;
      final wasSub = substituteParticipantIds.contains(userId);

      await runMutation(
        busyIds: {userId},
        optimistic: () => _removeActorPlayerByUserId(userId),
        revert: () {
          if (removed == null) {
            selectedUserIds.add(userId);
            return;
          }
          selectedUserIds.add(userId);
          captainParticipantId.value = prevCap;
          viceCaptainParticipantId.value = prevVice;
          if (wasSub) substituteParticipantIds.add(userId);
          final match = currentMatch.value;
          currentMatch.value = match.copyWith(
            announcedPlayers: [...match.announcedPlayers, removed],
          );
        },
        call: () => _announcedApi.removeAnnouncedPlayers(
          teamMatchId: mid,
          actorTeamId: actorTeamId,
          userIds: [userId],
        ),
      );
      return;
    }

    if (isAnnouncedForOpponent(userId)) {
      AppSnackbar.error(
        title: 'Already announced',
        message: 'This player is already announced for the opponent.',
      );
      return;
    }

    final member = findRosterMember(userId);
    if (member == null) return;
    final h = member.userHelper;
    final role = defaultAnnouncedRoleForSport(currentMatch.value.sportType);
    final isCap = captainParticipantId.value == userId;
    final isVice = viceCaptainParticipantId.value == userId;
    final isSub = substituteParticipantIds.contains(userId);
    final payload = AnnouncedPlayerCreatePayload(
      name: h.getDisplayName(),
      avatar: h.getAvatar(),
      email: h.getEmail(),
      userId: userId,
      role: role,
      isCaption: isCap,
      isWiseCaption: isVice,
      isSubstitute: isSub,
    );
    final optimisticRow = AnnouncedPlayerModel(
      teamId: actorTeamId,
      name: h.getDisplayName(),
      avatar: h.getAvatar(),
      email: h.getEmail(),
      userId: userId,
      role: role,
      isCaption: isCap,
      isWiseCaption: isVice,
      isSubstitute: isSub,
    );

    await runMutation(
      busyIds: {userId},
      optimistic: () {
        selectedUserIds.add(userId);
        final match = currentMatch.value;
        currentMatch.value = match.copyWith(
          announcedPlayers: [...match.announcedPlayers, optimisticRow],
        );
      },
      revert: () => _removeActorPlayerByUserId(userId),
      call: () => _announcedApi.addAnnouncedPlayers(
        teamMatchId: mid,
        actorTeamId: actorTeamId,
        players: [payload],
      ),
    );
  }

  Future<void> setCaptain(String participantId) async {
    if (!isSquadParticipant(participantId) ||
        interactionsLocked ||
        isBusy(participantId)) {
      return;
    }
    final clearing = captainParticipantId.value == participantId;
    final newCap = clearing ? null : participantId;
    var newVice = viceCaptainParticipantId.value;
    final newSubs = Set<String>.from(substituteParticipantIds);
    if (newCap != null) {
      if (newVice == participantId) newVice = null;
      newSubs.remove(participantId);
    }
    final busy = <String>{participantId};
    final oldCap = captainParticipantId.value;
    if (oldCap != null) busy.add(oldCap);
    await _patchMeta(
      busyIds: busy,
      captainId: newCap,
      viceCaptainId: newVice,
      substituteIds: newSubs,
    );
  }

  Future<void> setViceCaptain(String participantId) async {
    if (!isSquadParticipant(participantId) ||
        interactionsLocked ||
        isBusy(participantId)) {
      return;
    }
    final clearing = viceCaptainParticipantId.value == participantId;
    final newVice = clearing ? null : participantId;
    var newCap = captainParticipantId.value;
    final newSubs = Set<String>.from(substituteParticipantIds);
    if (newVice != null) {
      if (newCap == participantId) newCap = null;
      newSubs.remove(participantId);
    }
    final busy = <String>{participantId};
    final oldVice = viceCaptainParticipantId.value;
    if (oldVice != null) busy.add(oldVice);
    await _patchMeta(
      busyIds: busy,
      captainId: newCap,
      viceCaptainId: newVice,
      substituteIds: newSubs,
    );
  }

  Future<void> toggleSubstitute(String participantId) async {
    if (!isSquadParticipant(participantId) ||
        interactionsLocked ||
        isBusy(participantId)) {
      return;
    }
    final newSubs = Set<String>.from(substituteParticipantIds);
    var newCap = captainParticipantId.value;
    var newVice = viceCaptainParticipantId.value;
    if (newSubs.contains(participantId)) {
      newSubs.remove(participantId);
    } else {
      newSubs.add(participantId);
      if (newCap == participantId) newCap = null;
      if (newVice == participantId) newVice = null;
    }
    await _patchMeta(
      busyIds: {participantId},
      captainId: newCap,
      viceCaptainId: newVice,
      substituteIds: newSubs,
    );
  }

  Future<void> addGuest(GuestDraft draft) async {
    if (interactionsLocked) return;
    final mid = matchId;
    if (mid == null || mid.isEmpty) return;

    final isCap = captainParticipantId.value == draft.localId;
    final isVice = viceCaptainParticipantId.value == draft.localId;
    final payload = draft.toCreatePayload(
      isCaption: isCap,
      isWiseCaption: isVice,
    );
    final optimisticRow = AnnouncedPlayerModel(
      teamId: actorTeamId,
      name: draft.name,
      avatar: draft.avatar,
      isGuest: true,
      guestId: draft.localId,
      role: draft.role,
      isCaption: isCap,
      isWiseCaption: isVice,
      isSubstitute: draft.isSubstitute,
    );

    await runMutation(
      busyIds: {draft.localId},
      optimistic: () {
        if (draft.isSubstitute) {
          substituteParticipantIds.add(draft.localId);
        }
        final match = currentMatch.value;
        currentMatch.value = match.copyWith(
          announcedPlayers: [...match.announcedPlayers, optimisticRow],
        );
      },
      revert: () => _removeActorPlayerByParticipantId(draft.localId),
      call: () => _announcedApi.addAnnouncedPlayers(
        teamMatchId: mid,
        actorTeamId: actorTeamId,
        players: [payload],
      ),
    );
  }

  Future<void> removeGuest(String participantId) async {
    if (interactionsLocked || isBusy(participantId)) return;
    final mid = matchId;
    if (mid == null || mid.isEmpty) return;

    AnnouncedPlayerModel? guest;
    for (final g in serverGuests) {
      if (g.participantId == participantId) {
        guest = g;
        break;
      }
    }
    if (guest == null) return;

    final uid = guest.userIdHelper.getId();
    final guestMongoId = uid == null ? guest.guestId : null;
    final removed = guest;
    final prevCap = captainParticipantId.value;
    final prevVice = viceCaptainParticipantId.value;
    final wasSub = substituteParticipantIds.contains(participantId);

    await runMutation(
      busyIds: {participantId},
      optimistic: () => _removeActorPlayerByParticipantId(participantId),
      revert: () {
        captainParticipantId.value = prevCap;
        viceCaptainParticipantId.value = prevVice;
        if (wasSub) substituteParticipantIds.add(participantId);
        final match = currentMatch.value;
        currentMatch.value = match.copyWith(
          announcedPlayers: [...match.announcedPlayers, removed],
        );
      },
      call: () => _announcedApi.removeAnnouncedPlayers(
        teamMatchId: mid,
        actorTeamId: actorTeamId,
        userIds: uid != null ? [uid] : const [],
        guestIds: guestMongoId != null ? [guestMongoId] : const [],
      ),
    );
  }
}
