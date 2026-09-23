import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../match_up/team_logo.dart';
import '../../core/config/constants.dart';
import '../../match_up/announced_players/model/announced_player_model.dart';
import '../../match_up/model/team_match_model.dart';
import 'util/announced_player_roles_helpers.dart';
import 'guest_sheets.dart';
import 'manage_announced_players_controller.dart';

/// Opens a modal sheet to toggle active roster members as announced players.
Future<void> openManageAnnouncedPlayersSheet({
  required BuildContext context,
  required TeamMatchModel match,
  required String actorTeamId,
  required void Function(TeamMatchModel updated) onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(AppColors.backgroundColor),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => ManageAnnouncedPlayersSheet(
      match: match,
      actorTeamId: actorTeamId,
      onSaved: onSaved,
    ),
  );
}

class ManageAnnouncedPlayersSheet extends StatefulWidget {
  const ManageAnnouncedPlayersSheet({
    super.key,
    required this.match,
    required this.actorTeamId,
    required this.onSaved,
  });

  final TeamMatchModel match;
  final String actorTeamId;
  final void Function(TeamMatchModel updated) onSaved;

  @override
  State<ManageAnnouncedPlayersSheet> createState() =>
      _ManageAnnouncedPlayersSheetState();
}

class _ManageAnnouncedPlayersSheetState
    extends State<ManageAnnouncedPlayersSheet> {
  late final ManageAnnouncedPlayersController controller;

  @override
  void initState() {
    super.initState();
    controller = ManageAnnouncedPlayersController(
      match: widget.match,
      actorTeamId: widget.actorTeamId,
      onSaved: widget.onSaved,
    );
    // Not registered with Get — drive lifecycle manually.
    controller.onStart();
  }

  @override
  void dispose() {
    controller.onDelete();
    super.dispose();
  }

  Widget _rosterPlayerCard({
    required ManageAnnouncedPlayersController c,
    required bool locked,
    required Set<String> selectedIds,
    required Set<String> busyIds,
    required String userId,
    required String name,
    required String? avatar,
    required AnnouncedPlayerRole role,
    bool highlight = false,
  }) {
    final selected = selectedIds.contains(userId);
    final busy = busyIds.contains(userId);
    final takenByOpponent = !selected && c.isAnnouncedForOpponent(userId);
    return _PlayerCard(
      name: name,
      avatar: avatar,
      roleLabel: takenByOpponent
          ? 'Announced for opponent'
          : announcedRoleLabelForSport(widget.match.sportType, role),
      selected: selected,
      highlight: highlight,
      busy: busy,
      dimmed: takenByOpponent,
      showCheckbox: !takenByOpponent,
      onTap: locked || busy || takenByOpponent
          ? null
          : () => c.toggleMember(userId),
      trailing: selected
          ? _MetaToggles(controller: c, participantId: userId)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final c = controller;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Obx(() {
            final loadingRoster = c.loadingRoster.value;
            final locked = c.interactionsLocked;
            // Read selection here — ListView.builder itemBuilder runs too late for Obx.
            final selectedIds = c.selectedUserIds.toSet();
            final busyIds = c.busyParticipantIds.toSet();
            final guestRows = c.visibleGuestRows;
            final orphans = c.orphans;
            final roster = c.roster.toList();
            final rosterError = c.rosterError.value;

            final body = <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    TeamLogo(url: c.teamLogo, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.teamName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                    ),
                    if (c.syncing.value)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (c.isUnranked)
                      TextButton.icon(
                        onPressed: locked
                            ? null
                            : () async {
                                final draft = await showAddGuestSheet(
                                  context: context,
                                  sport: widget.match.sportType,
                                );
                                if (draft == null) return;
                                await c.addGuest(draft);
                              },
                        icon: const Icon(
                          Icons.person_add_alt_outlined,
                          size: 18,
                        ),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(AppColors.primaryColor),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ),
              if (c.isUnranked && guestRows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final g in guestRows)
                        _PlayerCard(
                          name: g.name,
                          avatar: g.avatar,
                          roleLabel: announcedRoleLabelForSport(
                            widget.match.sportType,
                            g.role,
                          ),
                          selected: true,
                          showCheckbox: false,
                          busy: busyIds.contains(g.participantId),
                          onTap: null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MetaToggles(
                                controller: c,
                                participantId: g.participantId,
                              ),
                              IconButton(
                                tooltip: 'Remove guest',
                                onPressed: locked ||
                                        busyIds.contains(g.participantId)
                                    ? null
                                    : () => c.removeGuest(g.participantId),
                                icon: const Icon(Icons.close_rounded),
                                color: const Color(
                                  AppColors.textSecondaryColor,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (loadingRoster)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(AppColors.primaryColor),
                      ),
                    ),
                  ),
                )
              else if (rosterError != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        rosterError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(AppColors.textSecondaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: c.loadRoster,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final o in orphans)
                        if (o.userIdHelper.getId() != null)
                          _rosterPlayerCard(
                            c: c,
                            locked: locked,
                            selectedIds: selectedIds,
                            busyIds: busyIds,
                            userId: o.userIdHelper.getId()!,
                            name: o.name,
                            avatar: o.avatar,
                            role: o.role,
                            highlight: true,
                          ),
                      for (final m in roster)
                        if (m.userHelper.getId() != null)
                          _rosterPlayerCard(
                            c: c,
                            locked: locked,
                            selectedIds: selectedIds,
                            busyIds: busyIds,
                            userId: m.userHelper.getId()!,
                            name: m.userHelper.getDisplayName(),
                            avatar: m.userHelper.getAvatar(),
                            role: c.roleForUserId(m.userHelper.getId()!),
                          ),
                    ],
                  ),
                ),
            ];

            return ListView(
              controller: scrollController,
              padding: EdgeInsets.only(bottom: 12 + bottomPad),
              children: body,
            );
          });
        },
      ),
    );
  }
}

class _MetaToggles extends StatelessWidget {
  const _MetaToggles({
    required this.controller,
    required this.participantId,
  });

  final ManageAnnouncedPlayersController controller;
  final String participantId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cap = controller.captainParticipantId.value == participantId;
      final vice =
          controller.viceCaptainParticipantId.value == participantId;
      final sub = controller.substituteParticipantIds.contains(participantId);
      final disabled = controller.interactionsLocked ||
          controller.isBusy(participantId);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetaChip(
            label: 'C',
            tooltip: cap ? 'Clear captain' : 'Captain',
            active: cap,
            activeColor: const Color(AppColors.primaryColor),
            disabled: disabled,
            onTap: () => controller.setCaptain(participantId),
          ),
          const SizedBox(width: 6),
          _MetaChip(
            label: 'VC',
            tooltip: vice ? 'Clear vice-captain' : 'Vice-captain',
            active: vice,
            activeColor: const Color(AppColors.secondaryColor),
            disabled: disabled,
            onTap: () => controller.setViceCaptain(participantId),
          ),
          const SizedBox(width: 6),
          _MetaChip(
            label: 'SUB',
            tooltip: sub ? 'Clear substitute' : 'Substitute',
            active: sub,
            activeColor: const Color(AppColors.textSecondaryColor),
            disabled: disabled,
            onTap: () => controller.toggleSubstitute(participantId),
          ),
        ],
      );
    });
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? activeColor.withValues(alpha: 0.16)
            : const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? activeColor
                    : const Color(AppColors.dividerColor),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.2,
                color: active
                    ? activeColor
                    : const Color(AppColors.textSecondaryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.roleLabel,
    required this.selected,
    this.avatar,
    this.onTap,
    this.trailing,
    this.highlight = false,
    this.showCheckbox = true,
    this.busy = false,
    this.dimmed = false,
  });

  final String name;
  final String? avatar;
  final String roleLabel;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool highlight;
  final bool showCheckbox;
  final bool busy;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlight ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: highlight
                      ? Colors.orange.withValues(alpha: 0.2)
                      : const Color(AppColors.primaryColor)
                          .withValues(alpha: 0.1),
                  backgroundImage: avatar != null && avatar!.isNotEmpty
                      ? AppNetworkImage.provider(avatar!)
                      : null,
                  child: avatar == null || avatar!.isEmpty
                      ? Icon(
                          highlight
                              ? Icons.person_off_outlined
                              : Icons.person,
                          color: highlight
                              ? Colors.orange.shade800
                              : const Color(AppColors.primaryColor),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(AppColors.textColor),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: highlight
                              ? Colors.orange.shade900
                              : const Color(AppColors.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                if (showCheckbox) ...[
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.textSecondaryColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!dimmed) return card;
    return Opacity(opacity: 0.45, child: card);
  }
}
