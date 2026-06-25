import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/announced_players/announced_players_service.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/model/team_model.dart';
import '../../team/members/model/team_member_model.dart';
import '../../team/members/team_member_service.dart';

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

class _ManageAnnouncedPlayersSheetBody extends StatefulWidget {
  const _ManageAnnouncedPlayersSheetBody({
    required this.match,
    required this.actorTeamId,
    required this.onSaved,
  });

  final TeamMatchModel match;
  final String actorTeamId;
  final void Function(TeamMatchModel updated) onSaved;

  @override
  State<_ManageAnnouncedPlayersSheetBody> createState() =>
      _ManageAnnouncedPlayersSheetBodyState();
}

class _ManageAnnouncedPlayersSheetBodyState
    extends State<_ManageAnnouncedPlayersSheetBody> {
  final AnnouncedPlayersService _announcedApi = AnnouncedPlayersService();
  final TeamMemberService _memberApi = TeamMemberService();

  List<TeamMemberModel> _roster = const [];
  List<AnnouncedPlayerModel> _orphans = const [];
  bool _loadingRoster = true;
  String? _rosterError;
  late Set<String> _selectedUserIds;
  String? _captainUserId;
  String? _viceCaptainUserId;
  bool _saving = false;

  String? get _matchId => widget.match.id;

  @override
  void initState() {
    super.initState();
    final announced = widget.match.announcedPlayers.where(
      (p) => p.teamIdHelper.getId() == widget.actorTeamId,
    );
    _selectedUserIds = {
      for (final p in announced)
        if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
    };
    for (final p in announced) {
      final uid = p.userIdHelper.getId();
      if (uid == null) continue;
      if (p.isCaption) _captainUserId = uid;
      if (p.isWiseCaption) _viceCaptainUserId = uid;
    }
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _loadingRoster = true;
      _rosterError = null;
    });
    final List<TeamMemberModel> all = [];
    var page = 1;
    const limit = 50;
    while (true) {
      final res = await _memberApi.listForTeam(
        widget.actorTeamId,
        TeamMemberRosterFilterQuery(
          status: TeamMemberStatus.active,
          page: page,
          limit: limit,
        ),
      );
      if (res == null || res.data.isEmpty) break;
      all.addAll(res.data);
      if (!res.hasNextPage) break;
      page++;
    }
    if (!mounted) return;
    final rosterIds = {
      for (final m in all)
        if (m.userHelper.getId() != null) m.userHelper.getId()!,
    };
    final orphans = widget.match.announcedPlayers.where((p) {
      if (p.teamIdHelper.getId() != widget.actorTeamId) return false;
      final uid = p.userIdHelper.getId();
      if (uid == null) return true;
      return !rosterIds.contains(uid);
    }).toList();

    setState(() {
      _roster = all;
      _orphans = orphans;
      _loadingRoster = false;
      if (all.isEmpty && orphans.isEmpty) {
        _rosterError = 'No active members found for this team.';
      }
    });
  }

  TeamMemberModel? _findRosterMember(String userId) {
    for (final m in _roster) {
      if (m.userHelper.getId() == userId) return m;
    }
    return null;
  }

  void _toggle(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds = {..._selectedUserIds}..remove(userId);
        if (_captainUserId == userId) _captainUserId = null;
        if (_viceCaptainUserId == userId) _viceCaptainUserId = null;
      } else {
        _selectedUserIds = {..._selectedUserIds, userId};
      }
    });
  }

  void _onCaptainTap(String userId) {
    if (!_selectedUserIds.contains(userId) || _saving || _loadingRoster) {
      return;
    }
    setState(() {
      if (_captainUserId == userId) {
        _captainUserId = null;
      } else {
        _captainUserId = userId;
        if (_viceCaptainUserId == userId) _viceCaptainUserId = null;
      }
    });
  }

  void _onViceCaptainTap(String userId) {
    if (!_selectedUserIds.contains(userId) || _saving || _loadingRoster) {
      return;
    }
    setState(() {
      if (_viceCaptainUserId == userId) {
        _viceCaptainUserId = null;
      } else {
        _viceCaptainUserId = userId;
        if (_captainUserId == userId) _captainUserId = null;
      }
    });
  }

  Widget _captainViceToggles(String userId) {
    final cap = _captainUserId == userId;
    final vice = _viceCaptainUserId == userId;
    final disabled = _saving || _loadingRoster;
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
              onTap: disabled ? null : () => _onCaptainTap(userId),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
                ? const Color(AppColors.secondaryColor).withValues(alpha: 0.14)
                : const Color(AppColors.backgroundColor),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: disabled ? null : () => _onViceCaptainTap(userId),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
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

  List<AnnouncedPlayerUpdatePayload> _buildLeadershipPatches(
    List<AnnouncedPlayerModel> slice, {
    required String? captainUserId,
    required String? viceCaptainUserId,
  }) {
    final updates = <AnnouncedPlayerUpdatePayload>[];
    for (final p in slice) {
      final uid = p.userIdHelper.getId();
      if (uid == null) continue;
      final wantCaptain = captainUserId == uid;
      final wantVice = viceCaptainUserId == uid;
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

  Future<void> _save() async {
    final mid = _matchId;
    if (mid == null || mid.isEmpty) {
      AppSnackbar.error(title: 'Missing match', message: 'Cannot save squad.');
      return;
    }

    final announced = widget.match.announcedPlayers.where(
      (p) => p.teamIdHelper.getId() == widget.actorTeamId,
    );
    final previousIds = {
      for (final p in announced)
        if (p.userIdHelper.getId() != null) p.userIdHelper.getId()!,
    };

    final toRemove = previousIds.difference(_selectedUserIds).toList();
    final toAddIds = _selectedUserIds.difference(previousIds).toList();
    final rosterChanged = toRemove.isNotEmpty || toAddIds.isNotEmpty;
    final capEffective =
        _captainUserId != null && _selectedUserIds.contains(_captainUserId)
        ? _captainUserId
        : null;
    final viceEffective =
        _viceCaptainUserId != null &&
            _selectedUserIds.contains(_viceCaptainUserId)
        ? _viceCaptainUserId
        : null;
    final leadershipOnlyPatches = rosterChanged
        ? const <AnnouncedPlayerUpdatePayload>[]
        : _buildLeadershipPatches(
            announced.toList(),
            captainUserId: capEffective,
            viceCaptainUserId: viceEffective,
          );

    if (!rosterChanged && leadershipOnlyPatches.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      List<AnnouncedPlayerModel> latestSlice = announced.toList();

      if (toRemove.isNotEmpty) {
        final afterRemove = await _announcedApi.removeAnnouncedPlayers(
          teamMatchId: mid,
          actorTeamId: widget.actorTeamId,
          userIds: toRemove,
        );
        latestSlice = afterRemove;
      }

      if (toAddIds.isNotEmpty) {
        final role = _defaultRoleForSport(widget.match.sportType);
        final payloads = <AnnouncedPlayerCreatePayload>[];
        for (final uid in toAddIds) {
          final m = _findRosterMember(uid);
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
          latestSlice = await _announcedApi.addAnnouncedPlayers(
            teamMatchId: mid,
            actorTeamId: widget.actorTeamId,
            players: payloads,
          );
        }
      }

      final leadershipPatches = _buildLeadershipPatches(
        latestSlice,
        captainUserId: capEffective,
        viceCaptainUserId: viceEffective,
      );
      if (leadershipPatches.isNotEmpty) {
        latestSlice = await _announcedApi.updateAnnouncedPlayers(
          teamMatchId: mid,
          actorTeamId: widget.actorTeamId,
          updates: leadershipPatches,
        );
      }

      final merged = mergeAnnouncedPlayersForTeam(
        widget.match,
        widget.actorTeamId,
        latestSlice,
      );
      widget.onSaved(merged);
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(
          title: 'Squad updated',
          message: 'Announced players were saved.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          title: 'Could not save',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: _saving || _loadingRoster
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _saving || _loadingRoster ? null : _save,
                      child: _saving
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
                child: _loadingRoster
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(AppColors.primaryColor),
                          ),
                        ),
                      )
                    : _rosterError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _rosterError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(AppColors.textSecondaryColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadRoster,
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
                        itemCount: _orphans.length + _roster.length,
                        itemBuilder: (context, i) {
                          if (i < _orphans.length) {
                            final o = _orphans[i];
                            final uid = o.userIdHelper.getId();
                            if (uid == null) {
                              return const SizedBox.shrink();
                            }
                            final selected = _selectedUserIds.contains(uid);
                            final avatar = o.avatar;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _saving ? null : () => _toggle(uid),
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
                                          backgroundImage:
                                              avatar != null &&
                                                  avatar.isNotEmpty
                                              ? NetworkImage(avatar)
                                              : null,
                                          child:
                                              avatar == null || avatar.isEmpty
                                              ? Icon(
                                                  Icons.person_off_outlined,
                                                  color: Colors.orange.shade800,
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
                                                  fontWeight: FontWeight.w600,
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
                                                  color: Colors.orange.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (selected) ...[
                                          const SizedBox(width: 8),
                                          _captainViceToggles(uid),
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
                                                  AppColors.textSecondaryColor,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          final m = _roster[i - _orphans.length];
                          final uid = m.userHelper.getId();
                          if (uid == null) return const SizedBox.shrink();
                          final selected = _selectedUserIds.contains(uid);
                          final name = m.userHelper.getDisplayName();
                          final avatar = m.userHelper.getAvatar();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _saving ? null : () => _toggle(uid),
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
                                        backgroundImage:
                                            avatar != null &&
                                                avatar.isNotEmpty
                                            ? NetworkImage(avatar)
                                            : null,
                                        child:
                                            avatar == null || avatar.isEmpty
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
                                            color: Color(AppColors.textColor),
                                          ),
                                        ),
                                      ),
                                      if (selected) ...[
                                        const SizedBox(width: 8),
                                        _captainViceToggles(uid),
                                      ],
                                      const SizedBox(width: 8),
                                      Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: selected
                                            ? const Color(AppColors.primaryColor)
                                            : const Color(
                                                AppColors.textSecondaryColor,
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
