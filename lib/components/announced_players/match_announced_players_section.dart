import 'package:flutter/material.dart';

import '../../core/config/constants.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import 'manage_announced_players_sheet.dart';

/// Header row height: fits two lines of team title + vertical center with edit slot.
const double _kSquadHeaderMinHeight = 44;
const double _kSquadHeaderEditSlot = 40;

/// Player tile row height in squad grids (avatar + name).
const double _kPlayerGridTileExtent = 132;
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

/// Shows announced squads for both challenge teams; edit control only for [myTeamId].
class MatchAnnouncedPlayersSection extends StatelessWidget {
  const MatchAnnouncedPlayersSection({
    super.key,
    required this.match,
    required this.myTeamId,
    required this.onMatchUpdated,
  });

  final TeamMatchModel match;
  final String myTeamId;
  final ValueChanged<TeamMatchModel> onMatchUpdated;

  static bool allowsAnnouncedPlayerEdits(TeamMatchModel m) {
    if (m.cricketState != null) return false;
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

  @override
  Widget build(BuildContext context) {
    final fromId = match.fromTeamHelper.getId() ?? '';
    final toId = match.toTeamHelper.getId() ?? '';
    final fromName = match.fromTeamHelper.getDisplayName();
    final toName = match.toTeamHelper.getDisplayName();

    final fromPlayers = match.announcedPlayers
        .where((p) => p.teamIdHelper.getId() == fromId)
        .toList();
    _sortAnnouncedPlayersForDisplay(fromPlayers);

    final toPlayers = match.announcedPlayers
        .where((p) => p.teamIdHelper.getId() == toId)
        .toList();
    _sortAnnouncedPlayersForDisplay(toPlayers);

    final canEdit =
        allowsAnnouncedPlayerEdits(match) &&
        myTeamId.isNotEmpty &&
        (myTeamId == fromId || myTeamId == toId);

    // Same side order as [MatchChallengeVersusHeader]: fromTeam left, toTeam right.
    return _SquadSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TeamSquadBlock(
              teamLabel: fromName,
              players: fromPlayers,
              showEdit: canEdit && myTeamId == fromId,
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
              teamLabel: toName,
              players: toPlayers,
              showEdit: canEdit && myTeamId == toId,
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
    required this.teamLabel,
    required this.players,
    required this.showEdit,
    required this.onEdit,
  });

  final String teamLabel;
  final List<AnnouncedPlayerModel> players;
  final bool showEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
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
        LayoutBuilder(
          builder: (context, constraints) {
            if (players.isEmpty) {
              return SizedBox(
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
              );
            }
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
                  child: _AnnouncedPlayerChip(players[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AnnouncedPlayerChip extends StatelessWidget {
  const _AnnouncedPlayerChip(this.player);

  final AnnouncedPlayerModel player;

  @override
  Widget build(BuildContext context) {
    final avatar = player.avatar;
    return Container(
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
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Color(AppColors.primaryColor),
                          size: 28,
                        )
                      : null,
                ),
                if (player.isCaption || player.isWiseCaption)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (player.isCaption)
                          Tooltip(
                            message: 'Captain',
                            child: _LeadershipChip(
                              label: 'C',
                              foreground: const Color(AppColors.primaryColor),
                              background: Colors.white,
                              compact: true,
                            ),
                          ),
                        if (player.isCaption && player.isWiseCaption)
                          const SizedBox(height: 3),
                        if (player.isWiseCaption)
                          Tooltip(
                            message: 'Vice-captain',
                            child: _LeadershipChip(
                              label: 'VC',
                              foreground: const Color(AppColors.secondaryColor),
                              background: Colors.white,
                              compact: true,
                            ),
                          ),
                      ],
                    ),
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
        ],
      ),
    );
  }
}

class _LeadershipChip extends StatelessWidget {
  const _LeadershipChip({
    required this.label,
    required this.foreground,
    required this.background,
    this.compact = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padH = compact ? 5.0 : 8.0;
    final padV = compact ? 2.0 : 3.0;
    final fontSize = compact ? 9.0 : 10.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: foreground,
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
