import 'package:flutter/material.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../match_up/challenge/challenge_controller.dart';
import '../../match_up/guest_join/guest_join_service.dart';
import '../../match_up/model/team_match_model.dart';
import '../../team/members/model/team_member_model.dart';

class ExploreMatchGuestJoinActions extends StatefulWidget {
  const ExploreMatchGuestJoinActions({super.key, required this.match});

  final TeamMatchModel match;

  @override
  State<ExploreMatchGuestJoinActions> createState() =>
      _ExploreMatchGuestJoinActionsState();
}

class _ExploreMatchGuestJoinActionsState
    extends State<ExploreMatchGuestJoinActions> {
  final GuestJoinService _service = GuestJoinService();
  GuestJoinStatus? _status;
  bool _busy = false;

  String? get _userId => Get.isRegistered<AuthStateController>()
      ? Get.find<AuthStateController>().user?.id
      : null;

  String get _fromTeamId => widget.match.fromTeamHelper.getId() ?? '';
  String get _toTeamId => widget.match.toTeamHelper.getId() ?? '';
  String get _matchId => widget.match.id ?? '';

  List<String> get _openTeamIds {
    if (_status != null) return _status!.openTeamIds;
    final settings = widget.match.guestJoin;
    return [
      if (settings?.fromTeamOpen == true && _fromTeamId.isNotEmpty) _fromTeamId,
      if (settings?.toTeamOpen == true && _toTeamId.isNotEmpty) _toTeamId,
    ];
  }

  String? get _joinedTeamId {
    if (_status != null) return _status!.joinedTeamId;
    final userId = _userId;
    if (userId == null) return null;
    for (final player in widget.match.announcedPlayers) {
      if (player.isGuest && player.userIdHelper.getId() == userId) {
        return player.teamIdHelper.getId();
      }
    }
    return null;
  }

  bool get _canEdit {
    final match = widget.match;
    if (!match.isUnranked ||
        match.cricketState != null ||
        match.footballState != null) {
      return false;
    }
    return !{
      TeamMatchStatus.rejected,
      TeamMatchStatus.expired,
      TeamMatchStatus.cancelled,
      TeamMatchStatus.completed,
      TeamMatchStatus.draw,
      TeamMatchStatus.abandoned,
    }.contains(match.status);
  }

  bool _hasActiveMembership(String teamId) {
    if (!Get.isRegistered<ChallengeController>()) return false;
    return Get.find<ChallengeController>().myMemberships.any(
      (membership) =>
          membership.status == TeamMemberStatus.active &&
          membership.teamId == teamId,
    );
  }

  Future<void> _join() async {
    await _mutate(() => _service.join(matchId: _matchId));
  }

  Future<void> _leave() async {
    await _mutate(() => _service.leave(_matchId));
  }

  Future<void> _mutate(Future<GuestJoinStatus?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = await action();
      if (next == null) {
        throw StateError('The guest-join update did not return a status.');
      }
      if (mounted) setState(() => _status = next);
      if (Get.isRegistered<QueryClient>()) {
        await Get.find<QueryClient>().invalidateQueries(
          queryKey: QueryKeys.explorePrefix,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(title: 'Could not update match', message: '$error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<ChallengeController>()) {
      return Obx(_buildActions);
    }
    return _buildActions();
  }

  Widget _buildActions() {
    if (!_canEdit || _matchId.isEmpty) return const SizedBox.shrink();

    final userId = _userId;
    final joinedTeamId = _joinedTeamId;
    final openTeamIds = _openTeamIds;
    final isMember =
        _hasActiveMembership(_fromTeamId) || _hasActiveMembership(_toTeamId);
    final canJoin =
        userId != null &&
        (joinedTeamId != null || (openTeamIds.isNotEmpty && !isMember));

    if (!canJoin) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(AppColors.dividerColor).withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              joinedTeamId == null
                  ? 'Become a participant'
                  : 'You are a participant',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (joinedTeamId == null)
            FilledButton(
              onPressed: _busy ? null : _join,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Join'),
            )
          else
            OutlinedButton(
              onPressed: _busy ? null : _leave,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Leave'),
            ),
        ],
      ),
    );
  }
}
