import 'package:flutter/material.dart';
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
import 'casual_guest_sheets.dart';

class GuestRowVm {
  const GuestRowVm({
    required this.participantId,
    required this.name,
    this.avatar,
    required this.role,
    required this.pending,
  });

  final String participantId;
  final String name;
  final String? avatar;
  final AnnouncedPlayerRole role;
  final bool pending;
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
  final RxBool saving = false.obs;
  final RxSet<String> removedGuestIds = <String>{}.obs;
  final RxList<GuestDraft> pendingGuests = <GuestDraft>[].obs;

  final RxList<TeamMemberModel> roster = <TeamMemberModel>[].obs;
  final RxBool loadingRoster = true.obs;
  final RxnString rosterError = RxnString();

  String? get matchId => currentMatch.value.id;

  bool get isCasual => currentMatch.value.isCasual;

  List<AnnouncedPlayerModel> get announcedForTeam => currentMatch
      .value.announcedPlayers
      .where((p) => p.teamIdHelper.getId() == actorTeamId)
      .toList();

  List<AnnouncedPlayerModel> get rosterAnnounced =>
      announcedForTeam.where((p) => !p.isGuest).toList();

  List<AnnouncedPlayerModel> get serverGuests =>
      announcedForTeam.where((p) => p.isGuest).toList();

  List<AnnouncedPlayerModel> get visibleServerGuests => serverGuests.where((g) {
        final pid = g.participantId;
        if (pid == null) return true;
        return !removedGuestIds.contains(pid);
      }).toList();

  List<GuestRowVm> get visibleGuestRows {
    final rows = <GuestRowVm>[];
    for (final g in visibleServerGuests) {
      final pid = g.participantId;
      if (pid == null) continue;
      rows.add(
        GuestRowVm(
          participantId: pid,
          name: g.name,
          avatar: g.avatar,
          role: g.role,
          pending: false,
        ),
      );
    }
    for (final d in pendingGuests) {
      rows.add(
        GuestRowVm(
          participantId: d.localId,
          name: d.name,
          avatar: d.avatar,
          role: d.role,
          pending: true,
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

  @override
  void onInit() {
    super.onInit();
    selectedUserIds.addAll({
      for (final p in rosterAnnounced)
        if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
    });
    _syncLeadershipFromServer();
    loadRoster();
  }

  void _syncLeadershipFromServer() {
    String? serverCaptain;
    String? serverVice;
    for (final p in announcedForTeam) {
      final pid = p.participantId;
      if (pid == null) continue;
      if (removedGuestIds.contains(pid)) continue;
      if (p.isCaption) serverCaptain = pid;
      if (p.isWiseCaption) serverVice = pid;
    }
    final pendingIds = {for (final d in pendingGuests) d.localId};
    if (captainParticipantId.value == null ||
        !pendingIds.contains(captainParticipantId.value)) {
      captainParticipantId.value = serverCaptain;
    }
    if (viceCaptainParticipantId.value == null ||
        !pendingIds.contains(viceCaptainParticipantId.value)) {
      viceCaptainParticipantId.value = serverVice;
    }
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

  TeamMemberModel? findRosterMember(String userId) {
    for (final m in roster) {
      if (m.userHelper.getId() == userId) return m;
    }
    return null;
  }

  bool isSquadParticipant(String participantId) {
    if (selectedUserIds.contains(participantId)) return true;
    if (pendingGuests.any((d) => d.localId == participantId)) return true;
    return visibleServerGuests.any((g) => g.participantId == participantId);
  }

  void toggle(String userId) {
    if (saving.value || loadingRoster.value) return;
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
      if (captainParticipantId.value == userId) {
        captainParticipantId.value = null;
      }
      if (viceCaptainParticipantId.value == userId) {
        viceCaptainParticipantId.value = null;
      }
    } else {
      selectedUserIds.add(userId);
    }
  }

  void onCaptainTap(String participantId) {
    if (!isSquadParticipant(participantId) ||
        saving.value ||
        loadingRoster.value) {
      return;
    }
    if (captainParticipantId.value == participantId) {
      captainParticipantId.value = null;
    } else {
      captainParticipantId.value = participantId;
      if (viceCaptainParticipantId.value == participantId) {
        viceCaptainParticipantId.value = null;
      }
    }
  }

  void onViceCaptainTap(String participantId) {
    if (!isSquadParticipant(participantId) ||
        saving.value ||
        loadingRoster.value) {
      return;
    }
    if (viceCaptainParticipantId.value == participantId) {
      viceCaptainParticipantId.value = null;
    } else {
      viceCaptainParticipantId.value = participantId;
      if (captainParticipantId.value == participantId) {
        captainParticipantId.value = null;
      }
    }
  }

  AnnouncedPlayerRole roleForUserId(String userId) {
    for (final p in rosterAnnounced) {
      if (p.userIdHelper.getId() == userId) return p.role;
    }
    return defaultAnnouncedRoleForSport(currentMatch.value.sportType);
  }

  void addPendingGuest(GuestDraft draft) {
    pendingGuests.add(draft);
  }

  void removeGuestFromUi(String participantId, {required bool pending}) {
    if (captainParticipantId.value == participantId) {
      captainParticipantId.value = null;
    }
    if (viceCaptainParticipantId.value == participantId) {
      viceCaptainParticipantId.value = null;
    }
    if (pending) {
      pendingGuests.removeWhere((d) => d.localId == participantId);
    } else {
      removedGuestIds.add(participantId);
    }
  }

  List<AnnouncedPlayerUpdatePayload> _buildLeadershipPatches(
    List<AnnouncedPlayerModel> slice, {
    required String? captainId,
    required String? viceCaptainId,
  }) {
    final updates = <AnnouncedPlayerUpdatePayload>[];
    for (final p in slice) {
      final pid = p.participantId;
      if (pid == null) continue;
      final uid = p.userIdHelper.getId();
      final wantCaptain = captainId == pid;
      final wantVice = viceCaptainId == pid;
      if (wantCaptain != p.isCaption || wantVice != p.isWiseCaption) {
        updates.add(
          AnnouncedPlayerUpdatePayload(
            userId: uid,
            guestId: uid == null ? p.guestId : null,
            isCaption: wantCaptain,
            isWiseCaption: wantVice,
          ),
        );
      }
    }
    return updates;
  }

  Future<void> save(BuildContext context) async {
    final mid = matchId;
    if (mid == null || mid.isEmpty) {
      AppSnackbar.error(
        title: 'Missing match',
        message: 'Cannot save squad.',
      );
      return;
    }

    final previousIds = {
      for (final p in rosterAnnounced)
        if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
    };
    final selected = selectedUserIds.toSet();
    final toRemove = previousIds.difference(selected).toList();
    final toAddIds = selected.difference(previousIds).toList();

    final guestsToRemove = <AnnouncedPlayerModel>[
      for (final g in serverGuests)
        if (g.participantId != null && removedGuestIds.contains(g.participantId))
          g,
    ];
    final guestsToAdd = List<GuestDraft>.from(pendingGuests);
    final guestChanged = guestsToRemove.isNotEmpty || guestsToAdd.isNotEmpty;
    final rosterChanged = toRemove.isNotEmpty || toAddIds.isNotEmpty;

    final capId = captainParticipantId.value;
    final viceId = viceCaptainParticipantId.value;
    final capEffective =
        capId != null && isSquadParticipant(capId) ? capId : null;
    final viceEffective =
        viceId != null && isSquadParticipant(viceId) ? viceId : null;

    final leadershipBaseline = [
      for (final p in announcedForTeam)
        if (p.participantId == null || !removedGuestIds.contains(p.participantId))
          p,
    ];
    final mutationPending = rosterChanged || guestChanged;
    final leadershipOnlyPatches = mutationPending
        ? const <AnnouncedPlayerUpdatePayload>[]
        : _buildLeadershipPatches(
            leadershipBaseline,
            captainId: capEffective,
            viceCaptainId: viceEffective,
          );

    if (!mutationPending && leadershipOnlyPatches.isEmpty) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    saving.value = true;
    try {
      var latestSlice = announcedForTeam;

      final removeUserIds = <String>[
        ...toRemove,
        for (final g in guestsToRemove)
          if (g.userIdHelper.getId() != null) g.userIdHelper.getId()!,
      ];
      final removeGuestMongoIds = <String>[
        for (final g in guestsToRemove)
          if (g.userIdHelper.getId() == null && g.guestId != null) g.guestId!,
      ];
      if (removeUserIds.isNotEmpty || removeGuestMongoIds.isNotEmpty) {
        latestSlice = await _announcedApi.removeAnnouncedPlayers(
          teamMatchId: mid,
          actorTeamId: actorTeamId,
          userIds: removeUserIds,
          guestIds: removeGuestMongoIds,
        );
        if (isClosed) return;
      }

      final addPayloads = <AnnouncedPlayerCreatePayload>[];
      if (toAddIds.isNotEmpty) {
        final role = defaultAnnouncedRoleForSport(currentMatch.value.sportType);
        for (final uid in toAddIds) {
          final m = findRosterMember(uid);
          if (m == null) continue;
          final h = m.userHelper;
          final id = h.getId();
          if (id == null) continue;
          addPayloads.add(
            AnnouncedPlayerCreatePayload(
              name: h.getDisplayName(),
              avatar: h.getAvatar(),
              email: h.getEmail(),
              userId: id,
              role: role,
              isCaption: uid == capEffective,
              isWiseCaption: uid == viceEffective,
            ),
          );
        }
      }
      for (final d in guestsToAdd) {
        addPayloads.add(
          d.toCreatePayload(
            isCaption: d.localId == capEffective,
            isWiseCaption: d.localId == viceEffective,
          ),
        );
      }
      if (addPayloads.isNotEmpty) {
        latestSlice = await _announcedApi.addAnnouncedPlayers(
          teamMatchId: mid,
          actorTeamId: actorTeamId,
          players: addPayloads,
        );
        if (isClosed) return;
      }

      var resolveCaptainId = capEffective;
      var resolveViceId = viceEffective;
      if (capEffective != null &&
          guestsToAdd.any((d) => d.localId == capEffective)) {
        final draft = guestsToAdd.firstWhere((d) => d.localId == capEffective);
        for (final p in latestSlice) {
          if (p.isGuest &&
              p.name == draft.name &&
              p.role == draft.role &&
              p.participantId != null) {
            resolveCaptainId = p.participantId;
            break;
          }
        }
      }
      if (viceEffective != null &&
          guestsToAdd.any((d) => d.localId == viceEffective)) {
        final draft = guestsToAdd.firstWhere((d) => d.localId == viceEffective);
        for (final p in latestSlice) {
          if (p.isGuest &&
              p.name == draft.name &&
              p.role == draft.role &&
              p.participantId != null) {
            resolveViceId = p.participantId;
            break;
          }
        }
      }

      final leadershipPatches = _buildLeadershipPatches(
        latestSlice,
        captainId: resolveCaptainId,
        viceCaptainId: resolveViceId,
      );
      if (leadershipPatches.isNotEmpty) {
        latestSlice = await _announcedApi.updateAnnouncedPlayers(
          teamMatchId: mid,
          actorTeamId: actorTeamId,
          updates: leadershipPatches,
        );
        if (isClosed) return;
      }

      final match = currentMatch.value;
      final kept = match.announcedPlayers
          .where((p) => p.teamIdHelper.getId() != actorTeamId)
          .toList();
      final merged = match.copyWith(
        announcedPlayers: [...kept, ...latestSlice],
      );
      currentMatch.value = merged;
      onSaved(merged);
      if (Get.isRegistered<QueryClient>()) {
        await Get.find<QueryClient>().invalidateQueries(
          queryKey: QueryKeys.matchChallengeDetail(mid),
        );
      }
      if (context.mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(
          title: 'Squad updated',
          message: 'Announced players were saved.',
        );
      }
    } catch (e) {
      if (!isClosed) {
        AppSnackbar.error(
          title: 'Could not save',
          message: e.toString(),
        );
      }
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
