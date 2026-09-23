import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/model/team_model.dart';
import 'util/announced_player_display_helpers.dart';
import 'util/announced_player_roles_helpers.dart';
import 'manage_announced_players_sheet.dart';

/// Header row height: fits two lines of team title + vertical center with edit slot.
const double _kSquadHeaderMinHeight = 44;
const double _kSquadHeaderEditSlot = 40;

/// Player tile row height in squad grids (avatar + name + role + optional lines).
const double _kPlayerGridTileExtent = 168;
/// Minimum squad-column width for two player tiles (tile ~104dp + spacing).
const double _kTwoPlayerColumnsMinWidth = 230;

/// Captain first, then vice-captain, then everyone else (name order within tier).
void _sortAnnouncedPlayersForDisplay(List<AnnouncedPlayerModel> players) {
  int tier(AnnouncedPlayerModel p) {
    if (p.isCaption) return 0;
    if (p.isWiseCaption) return 1;
    return 2;
  }

  players.sort((a, b) {
    final ta = tier(a);
    final tb = tier(b);
    if (ta != tb) return ta.compareTo(tb);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

/// Shows announced squads for both challenge teams; edit when [editableTeamIds] includes that side.
class MatchAnnouncedPlayersSection extends StatelessWidget {
  const MatchAnnouncedPlayersSection({
    super.key,
    required this.match,
    required this.myTeamId,
    required this.onMatchUpdated,
    this.editableTeamIds,
  });

  final TeamMatchModel match;
  final String myTeamId;
  final ValueChanged<TeamMatchModel> onMatchUpdated;

  /// Match team ids the current user may announce for. Defaults to [myTeamId] only.
  final Set<String>? editableTeamIds;

  static bool allowsAnnouncedPlayerEdits(TeamMatchModel m) {
    if (m.cricketState != null || m.footballState != null) return false;
    const terminal = {
      TeamMatchStatus.rejected,
      TeamMatchStatus.expired,
      TeamMatchStatus.cancelled,
      TeamMatchStatus.completed,
      TeamMatchStatus.draw,
      TeamMatchStatus.abandoned,
    };
    return !terminal.contains(m.status);
  }

  /// Minimum playing (non-substitute) players per team before scoring can start.
  /// Matches server [SCORING_MIN_ANNOUNCED_PLAYERS] (cricket and football min 5).
  static const int minAnnouncedPlayersPerTeam = 5;

  /// Playing announced count for [teamId]. Substitutes do not count.
  static int announcedCountForTeam(TeamMatchModel m, String teamId) {
    if (teamId.isEmpty) return 0;
    return m.announcedPlayers
        .where(
          (p) => p.teamIdHelper.getId() == teamId && !p.isSubstitute,
        )
        .length;
  }

  /// True when [teamId] has announced at least [minAnnouncedPlayersPerTeam].
  static bool teamHasAnnouncedPlayers(TeamMatchModel m, String teamId) {
    return announcedCountForTeam(m, teamId) >= minAnnouncedPlayersPerTeam;
  }

  /// True when both challenge teams have announced a full squad.
  static bool bothTeamsHaveAnnouncedPlayers(TeamMatchModel m) {
    final fromId = m.fromTeamHelper.getId() ?? '';
    final toId = m.toTeamHelper.getId() ?? '';
    return teamHasAnnouncedPlayers(m, fromId) &&
        teamHasAnnouncedPlayers(m, toId);
  }

  @override
  Widget build(BuildContext context) {
    final fromId = match.fromTeamHelper.getId() ?? '';
    final toId = match.toTeamHelper.getId() ?? '';
    final fromName = match.fromTeamHelper.getDisplayName();
    final toName = match.toTeamHelper.getDisplayName();

    final fromPlayers = match.announcedPlayers
        .where((p) => p.teamIdHelper.getId() == fromId)
        .toList();

    final toPlayers = match.announcedPlayers
        .where((p) => p.teamIdHelper.getId() == toId)
        .toList();

    final canEditBase = allowsAnnouncedPlayerEdits(match);
    final editable = editableTeamIds ??
        (myTeamId.isNotEmpty ? {myTeamId} : const <String>{});

    // Same side order as [MatchChallengeVersusHeader]: fromTeam left, toTeam right.
    return _SquadSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TeamSquadBlock(
              sport: match.sportType,
              teamLabel: fromName,
              players: fromPlayers,
              showEdit: canEditBase &&
                  fromId.isNotEmpty &&
                  editable.contains(fromId),
              onEdit: () => openManageAnnouncedPlayersSheet(
                context: context,
                match: match,
                actorTeamId: fromId,
                onSaved: onMatchUpdated,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TeamSquadBlock(
              sport: match.sportType,
              teamLabel: toName,
              players: toPlayers,
              showEdit: canEditBase &&
                  toId.isNotEmpty &&
                  editable.contains(toId),
              onEdit: () => openManageAnnouncedPlayersSheet(
                context: context,
                match: match,
                actorTeamId: toId,
                onSaved: onMatchUpdated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSquadBlock extends StatelessWidget {
  const _TeamSquadBlock({
    required this.sport,
    required this.teamLabel,
    required this.players,
    required this.showEdit,
    required this.onEdit,
  });

  final TeamSportType sport;
  final String teamLabel;
  final List<AnnouncedPlayerModel> players;
  final bool showEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final startingXi = players.where((p) => !p.isSubstitute).toList();
    final substitutes = players.where((p) => p.isSubstitute).toList();
    _sortAnnouncedPlayersForDisplay(startingXi);
    _sortAnnouncedPlayersForDisplay(substitutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kSquadHeaderMinHeight),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _kSquadHeaderEditSlot,
                height: _kSquadHeaderEditSlot,
              ),
              Expanded(
                child: Text(
                  teamLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.25,
                    color: Color(AppColors.textColor),
                  ),
                ),
              ),
              SizedBox(
                width: _kSquadHeaderEditSlot,
                height: _kSquadHeaderEditSlot,
                child: showEdit
                    ? IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 22),
                        tooltip: 'Manage squad',
                        color: const Color(AppColors.primaryColor),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            AppColors.primaryColor,
                          ).withValues(alpha: 0.08),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: _kSquadHeaderEditSlot,
                          height: _kSquadHeaderEditSlot,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (players.isEmpty)
          const SizedBox(
            height: 72,
            child: Center(
              child: Text(
                'No players announced yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            ),
          )
        else ...[
          if (startingXi.isNotEmpty) ...[
            const _SquadSubheader(label: 'Starting XI'),
            const SizedBox(height: 6),
            _PlayerGrid(sport: sport, players: startingXi),
          ],
          if (substitutes.isNotEmpty) ...[
            if (startingXi.isNotEmpty) const SizedBox(height: 12),
            const _SquadSubheader(label: 'Substitutes'),
            const SizedBox(height: 6),
            _PlayerGrid(sport: sport, players: substitutes),
          ],
        ],
      ],
    );
  }
}

class _SquadSubheader extends StatelessWidget {
  const _SquadSubheader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Color(AppColors.textSecondaryColor),
      ),
    );
  }
}

class _PlayerGrid extends StatelessWidget {
  const _PlayerGrid({
    required this.sport,
    required this.players,
  });

  final TeamSportType sport;
  final List<AnnouncedPlayerModel> players;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth >= _kTwoPlayerColumnsMinWidth ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: _kPlayerGridTileExtent,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            return Center(
              child: _AnnouncedPlayerChip(
                sport: sport,
                player: players[index],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnnouncedPlayerChip extends StatelessWidget {
  const _AnnouncedPlayerChip({
    required this.sport,
    required this.player,
  });

  final TeamSportType sport;
  final AnnouncedPlayerModel player;

  void _openProfile() {
    final userId = player.userIdHelper.getId();
    if (userId == null || userId.isEmpty) return;
    Get.toNamed(
      AppConstants.routes.teamMemberProfile,
      arguments: {'userId': userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = player.avatar;
    final userId = player.userIdHelper.getId();
    final canOpenProfile = userId != null && userId.isNotEmpty;
    final badges = AnnouncedPlayerBadgeRow(
      isCaptain: player.isCaption,
      isViceCaptain: player.isWiseCaption,
      isSubstitute: player.isSubstitute,
      compact: true,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canOpenProfile ? _openProfile : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 104,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(AppColors.backgroundColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(
                        AppColors.primaryColor,
                      ).withValues(alpha: 0.12),
                      backgroundImage: avatar != null && avatar.isNotEmpty
                          ? AppNetworkImage.provider(avatar)
                          : null,
                      child: avatar == null || avatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Color(AppColors.primaryColor),
                              size: 28,
                            )
                          : null,
                    ),
                    if (badges.hasAny)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: badges,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Color(AppColors.textColor),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                announcedRoleLabelForSport(sport, player.role),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
              if (player.isSubstitute)
                const Text(
                  'Substitute',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
              if (player.isGuest)
                const Text(
                  'Guest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquadSectionCard extends StatelessWidget {
  const _SquadSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
