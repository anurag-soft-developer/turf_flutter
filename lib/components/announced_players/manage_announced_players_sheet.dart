import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/announced_players/announced_players_service.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/members/team_member_service.dart';

Duration? _noRetry(int count, Object error) => null;

/// Opens a modal sheet to toggle active roster members as announced players; persists via matchmaking API.
Future<void> openManageAnnouncedPlayersSheet({
  required BuildContext context,
  required TeamMatchModel match,
  required String actorTeamId,
  required void Function(TeamMatchModel updated) onSaved,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(AppColors.backgroundColor),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ManageAnnouncedPlayersSheetBody(
      match: match,
      actorTeamId: actorTeamId,
      onSaved: onSaved,
    ),
  );
}

AnnouncedPlayerRole _defaultRoleForSport(TeamSportType sport) {
  return switch (sport) {
    TeamSportType.cricket => AnnouncedPlayerRole.batsman,
    TeamSportType.football => AnnouncedPlayerRole.allrounder,
    _ => AnnouncedPlayerRole.allrounder,
  };
}

class _ManageAnnouncedPlayersSheetBody extends HookWidget {
  const _ManageAnnouncedPlayersSheetBody({
    required this.match,
    required this.actorTeamId,
    required this.onSaved,
  });

  final TeamMatchModel match;
  final String actorTeamId;
  final void Function(TeamMatchModel updated) onSaved;

  String? get _matchId => match.id;

  @override
  Widget build(BuildContext context) {
    final announcedApi = useMemoized(() => AnnouncedPlayersService());
    final memberApi = useMemoized(() => TeamMemberService());

    final announcedForTeam = useMemoized(
      () => match.announcedPlayers
          .where((p) => p.teamIdHelper.getId() == actorTeamId)
          .toList(),
      [match, actorTeamId],
    );

    final selectedUserIds = useState<Set<String>>({
      for (final p in announcedForTeam)
        if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
    });
    final captainUserId = useState<String?>(null);
    final viceCaptainUserId = useState<String?>(null);
    final saving = useState(false);

    useEffect(() {
      String? captain;
      String? vice;
      for (final p in announcedForTeam) {
        final uid = p.userIdHelper.getId();
        if (uid == null) continue;
        if (p.isCaption) captain = uid;
        if (p.isWiseCaption) vice = uid;
      }
      captainUserId.value = captain;
      viceCaptainUserId.value = vice;
      return null;
    }, [announcedForTeam]);

    final rosterQuery = useQuery<PaginatedResponse<TeamMemberModel>, Object>(
      QueryKeys.teamRoster(
        actorTeamId,
        status: TeamMemberStatus.active.name,
      ),
      (_) async {
        final page = await memberApi.listForTeam(
          actorTeamId,
          const TeamMemberRosterFilterQuery(
            status: TeamMemberStatus.active,
            limit: 100,
          ),
        );
        return page ?? EmptyPaginatedResponse<TeamMemberModel>();
      },
      retry: _noRetry,
    );

    final roster = rosterQuery.data?.data ?? const <TeamMemberModel>[];
    final rosterIds = {
      for (final m in roster)
        if (m.userHelper.getId() != null) m.userHelper.getId()!,
    };
    final orphans = announcedForTeam.where((p) {
      final uid = p.userIdHelper.getId();
      if (uid == null) return true;
      return !rosterIds.contains(uid);
    }).toList();

    final loadingRoster = rosterQuery.isLoading ||
        (rosterQuery.isFetching && rosterQuery.data == null);
    final rosterError = rosterQuery.isError
        ? (rosterQuery.error?.toString() ?? 'Failed to load roster.')
        : (rosterQuery.isSuccess && roster.isEmpty && orphans.isEmpty)
            ? 'No active members found for this team.'
            : null;

    TeamMemberModel? findRosterMember(String userId) {
      for (final m in roster) {
        if (m.userHelper.getId() == userId) return m;
      }
      return null;
    }

    void toggle(String userId) {
      final next = {...selectedUserIds.value};
      if (next.contains(userId)) {
        next.remove(userId);
        if (captainUserId.value == userId) captainUserId.value = null;
        if (viceCaptainUserId.value == userId) viceCaptainUserId.value = null;
      } else {
        next.add(userId);
      }
      selectedUserIds.value = next;
    }

    void onCaptainTap(String userId) {
      if (!selectedUserIds.value.contains(userId) ||
          saving.value ||
          loadingRoster) {
        return;
      }
      if (captainUserId.value == userId) {
        captainUserId.value = null;
      } else {
        captainUserId.value = userId;
        if (viceCaptainUserId.value == userId) {
          viceCaptainUserId.value = null;
        }
      }
    }

    void onViceCaptainTap(String userId) {
      if (!selectedUserIds.value.contains(userId) ||
          saving.value ||
          loadingRoster) {
        return;
      }
      if (viceCaptainUserId.value == userId) {
        viceCaptainUserId.value = null;
      } else {
        viceCaptainUserId.value = userId;
        if (captainUserId.value == userId) {
          captainUserId.value = null;
        }
      }
    }

    Widget captainViceToggles(String userId) {
      final cap = captainUserId.value == userId;
      final vice = viceCaptainUserId.value == userId;
      final disabled = saving.value || loadingRoster;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: cap ? 'Clear captain' : 'Captain',
            child: Material(
              color: cap
                  ? const Color(AppColors.primaryColor).withValues(alpha: 0.18)
                  : const Color(AppColors.backgroundColor),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: disabled ? null : () => onCaptainTap(userId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cap
                          ? const Color(AppColors.primaryColor)
                          : const Color(AppColors.dividerColor),
                    ),
                  ),
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: cap
                          ? const Color(AppColors.primaryColor)
                          : const Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: vice ? 'Clear vice-captain' : 'Vice-captain',
            child: Material(
              color: vice
                  ? const Color(AppColors.secondaryColor)
                      .withValues(alpha: 0.14)
                  : const Color(AppColors.backgroundColor),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: disabled ? null : () => onViceCaptainTap(userId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: vice
                          ? const Color(AppColors.secondaryColor)
                          : const Color(AppColors.dividerColor),
                    ),
                  ),
                  child: Text(
                    'VC',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.2,
                      color: vice
                          ? const Color(AppColors.secondaryColor)
                          : const Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    List<AnnouncedPlayerUpdatePayload> buildLeadershipPatches(
      List<AnnouncedPlayerModel> slice, {
      required String? captainId,
      required String? viceCaptainId,
    }) {
      final updates = <AnnouncedPlayerUpdatePayload>[];
      for (final p in slice) {
        final uid = p.userIdHelper.getId();
        if (uid == null) continue;
        final wantCaptain = captainId == uid;
        final wantVice = viceCaptainId == uid;
        if (wantCaptain != p.isCaption || wantVice != p.isWiseCaption) {
          updates.add(
            AnnouncedPlayerUpdatePayload(
              userId: uid,
              isCaption: wantCaptain,
              isWiseCaption: wantVice,
            ),
          );
        }
      }
      return updates;
    }

    Future<void> save() async {
      final mid = _matchId;
      if (mid == null || mid.isEmpty) {
        AppSnackbar.error(
          title: 'Missing match',
          message: 'Cannot save squad.',
        );
        return;
      }

      final previousIds = {
        for (final p in announcedForTeam)
          if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
      };

      final toRemove =
          previousIds.difference(selectedUserIds.value).toList();
      final toAddIds =
          selectedUserIds.value.difference(previousIds).toList();
      final rosterChanged = toRemove.isNotEmpty || toAddIds.isNotEmpty;
      final capEffective = captainUserId.value != null &&
              selectedUserIds.value.contains(captainUserId.value)
          ? captainUserId.value
          : null;
      final viceEffective = viceCaptainUserId.value != null &&
              selectedUserIds.value.contains(viceCaptainUserId.value)
          ? viceCaptainUserId.value
          : null;
      final leadershipOnlyPatches = rosterChanged
          ? const <AnnouncedPlayerUpdatePayload>[]
          : buildLeadershipPatches(
              announcedForTeam,
              captainId: capEffective,
              viceCaptainId: viceEffective,
            );

      if (!rosterChanged && leadershipOnlyPatches.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      saving.value = true;
      try {
        List<AnnouncedPlayerModel> latestSlice = announcedForTeam;

        if (toRemove.isNotEmpty) {
          latestSlice = await announcedApi.removeAnnouncedPlayers(
            teamMatchId: mid,
            actorTeamId: actorTeamId,
            userIds: toRemove,
          );
        }

        if (toAddIds.isNotEmpty) {
          final role = _defaultRoleForSport(match.sportType);
          final payloads = <AnnouncedPlayerCreatePayload>[];
          for (final uid in toAddIds) {
            final m = findRosterMember(uid);
            if (m == null) continue;
            final h = m.userHelper;
            final id = h.getId();
            if (id == null) continue;
            payloads.add(
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
          if (payloads.isNotEmpty) {
            latestSlice = await announcedApi.addAnnouncedPlayers(
              teamMatchId: mid,
              actorTeamId: actorTeamId,
              players: payloads,
            );
          }
        }

        final leadershipPatches = buildLeadershipPatches(
          latestSlice,
          captainId: capEffective,
          viceCaptainId: viceEffective,
        );
        if (leadershipPatches.isNotEmpty) {
          latestSlice = await announcedApi.updateAnnouncedPlayers(
            teamMatchId: mid,
            actorTeamId: actorTeamId,
            updates: leadershipPatches,
          );
        }

        final merged = mergeAnnouncedPlayersForTeam(
          match,
          actorTeamId,
          latestSlice,
        );
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
        if (context.mounted) {
          AppSnackbar.error(
            title: 'Could not save',
            message: e.toString(),
          );
        }
      } finally {
        saving.value = false;
      }
    }

    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Announced squad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: saving.value || loadingRoster
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: saving.value || loadingRoster ? null : save,
                      child: saving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tap members to include or exclude. Use C / VC for captain and vice-captain (selected players only). Tap again to clear.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.textSecondaryColor),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: loadingRoster
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(AppColors.primaryColor),
                          ),
                        ),
                      )
                    : rosterError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    rosterError,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(
                                        AppColors.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => rosterQuery.refetch(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16 + bottomPad,
                            ),
                            itemCount: orphans.length + roster.length,
                            itemBuilder: (context, i) {
                              if (i < orphans.length) {
                                final o = orphans[i];
                                final uid = o.userIdHelper.getId();
                                if (uid == null) {
                                  return const SizedBox.shrink();
                                }
                                final selected =
                                    selectedUserIds.value.contains(uid);
                                final avatar = o.avatar;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: saving.value
                                          ? null
                                          : () => toggle(uid),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: Colors.orange
                                                  .withValues(alpha: 0.2),
                                              backgroundImage: avatar !=
                                                          null &&
                                                      avatar.isNotEmpty
                                                  ? NetworkImage(avatar)
                                                  : null,
                                              child: avatar == null ||
                                                      avatar.isEmpty
                                                  ? Icon(
                                                      Icons.person_off_outlined,
                                                      color: Colors
                                                          .orange.shade800,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    o.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                      color: Color(
                                                        AppColors.textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Not on active roster — tap to remove from squad',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .orange.shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (selected) ...[
                                              const SizedBox(width: 8),
                                              captainViceToggles(uid),
                                            ],
                                            const SizedBox(width: 8),
                                            Icon(
                                              selected
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              color: selected
                                                  ? const Color(
                                                      AppColors.primaryColor,
                                                    )
                                                  : const Color(
                                                      AppColors
                                                          .textSecondaryColor,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final m = roster[i - orphans.length];
                              final uid = m.userHelper.getId();
                              if (uid == null) return const SizedBox.shrink();
                              final selected =
                                  selectedUserIds.value.contains(uid);
                              final name = m.userHelper.getDisplayName();
                              final avatar = m.userHelper.getAvatar();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: saving.value
                                        ? null
                                        : () => toggle(uid),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: const Color(
                                              AppColors.primaryColor,
                                            ).withValues(alpha: 0.1),
                                            backgroundImage: avatar != null &&
                                                    avatar.isNotEmpty
                                                ? NetworkImage(avatar)
                                                : null,
                                            child: avatar == null ||
                                                    avatar.isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    color: Color(
                                                      AppColors.primaryColor,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: Color(
                                                  AppColors.textColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (selected) ...[
                                            const SizedBox(width: 8),
                                            captainViceToggles(uid),
                                          ],
                                          const SizedBox(width: 8),
                                          Icon(
                                            selected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: selected
                                                ? const Color(
                                                    AppColors.primaryColor,
                                                  )
                                                : const Color(
                                                    AppColors
                                                        .textSecondaryColor,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

TeamMatchModel mergeAnnouncedPlayersForTeam(
  TeamMatchModel match,
  String teamId,
  List<AnnouncedPlayerModel> updatedForTeam,
) {
  final kept = match.announcedPlayers
      .where((p) => p.teamIdHelper.getId() != teamId)
      .toList();
  return TeamMatchModel(
    id: match.id,
    source: match.source,
    fromTeam: match.fromTeam,
    toTeam: match.toTeam,
    sportType: match.sportType,
    status: match.status,
    statusUpdatedBy: match.statusUpdatedBy,
    statusUpdatedAt: match.statusUpdatedAt,
    proposedSlots: match.proposedSlots,
    proposedTurfs: match.proposedTurfs,
    selectedSlotProposalId: match.selectedSlotProposalId,
    selectedTurfProposalId: match.selectedTurfProposalId,
    winnerTeam: match.winnerTeam,
    notes: match.notes,
    turfBookingId: match.turfBookingId,
    expiresAt: match.expiresAt,
    closedAt: match.closedAt,
    announcedPlayers: [...kept, ...updatedForTeam],
    cricketState: match.cricketState,
    footballState: match.footballState,
    createdAt: match.createdAt,
    updatedAt: match.updatedAt,
  );
}
