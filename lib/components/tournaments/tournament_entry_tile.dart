import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../match_up/team_logo.dart';
import '../../tournament/model/tournament_models.dart';
import '../../tournament/detail/tournament_detail_controller.dart';

class TournamentEntryTile extends GetView<TournamentDetailController> {
  const TournamentEntryTile({
    super.key,
    required this.entry,
    required this.onRemoveAccepted,
    this.onWithdrawRequest,
    this.onCancelInvite,
    this.showStatusAndDirection = true,
  });

  final TournamentEntryModel entry;
  final void Function(TournamentEntryModel entry) onRemoveAccepted;
  final void Function(TournamentEntryModel entry)? onWithdrawRequest;
  final void Function(TournamentEntryModel entry)? onCancelInvite;
  final bool showStatusAndDirection;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    return Card(
      child: ListTile(
        leading: TeamLogo(
          url: entry.teamLogo,
          size: 48,
          teamId: entry.teamId,
        ),
        title: Text(entry.teamName),
        subtitle: subtitle,
        isThreeLine: subtitle != null,
        trailing: _trailing(context),
      ),
    );
  }

  Widget? _subtitle() {
    final lines = <String>[];
    final place = entry.teamLocationLabel?.trim();
    if (place != null && place.isNotEmpty) {
      lines.add(place);
    }
    if (showStatusAndDirection) {
      lines.add('${entry.direction} · ${entry.status}');
    }
    if (lines.isEmpty) return null;
    return Text(
      lines.join('\n'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    );
  }

  Widget? _trailing(BuildContext context) {
    if (entry.status == 'accepted' &&
        controller.isOrganizer &&
        !controller.isRosterLocked) {
      return IconButton(
        tooltip: 'Remove team',
        onPressed: () => onRemoveAccepted(entry),
        icon: const Icon(Icons.person_remove_outlined),
      );
    }
    if (entry.status != 'pending') return null;

    if (entry.direction == 'invite' &&
        controller.isOrganizer &&
        onCancelInvite != null) {
      return TextButton(
        onPressed: () => onCancelInvite!(entry),
        child: const Text('Revoke'),
      );
    }

    final mine = controller.isMyTeamEntry(entry);

    if (entry.direction == 'invite' && mine) {
      return Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Accept',
            onPressed: () => controller.acceptInvite(entry.id),
            icon: const Icon(Icons.check),
          ),
          IconButton(
            tooltip: 'Decline',
            onPressed: () => controller.declineInvite(entry.id),
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }
    if (entry.direction == 'request' && mine && onWithdrawRequest != null) {
      return TextButton(
        onPressed: () => onWithdrawRequest!(entry),
        child: const Text('Withdraw'),
      );
    }
    if (entry.direction == 'request' && controller.isOrganizer) {
      return Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Accept',
            onPressed: () => controller.acceptRequest(entry.id),
            icon: const Icon(Icons.check),
          ),
          IconButton(
            tooltip: 'Decline',
            onPressed: () => controller.declineRequest(entry.id),
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }
    return null;
  }
}
