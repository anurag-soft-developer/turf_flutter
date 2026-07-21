import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../../core/auth/auth_state_controller.dart';
import '../../../core/config/constants.dart';
import '../../../core/models/following/following_model.dart';
import '../../../core/query/query_keys.dart';
import '../../../core/query/query_retry.dart';
import '../../../core/services/followings_service.dart';

/// Self-contained follow/unfollow pill for user or team profiles.
///
/// Hides itself when [targetId] is empty, or when following a user and that
/// user is the logged-in account.
class FollowButton extends HookWidget {
  const FollowButton({
    super.key,
    required this.targetId,
    this.recipientType = FollowRecipientType.user,
  });

  final String? targetId;
  final FollowRecipientType recipientType;

  @override
  Widget build(BuildContext context) {
    final id = targetId;
    final myId = Get.isRegistered<AuthStateController>()
        ? AuthStateController.instance.user?.id
        : null;

    final isSelfUser =
        recipientType == FollowRecipientType.user && id != null && id == myId;

    if (id == null || id.isEmpty || isSelfUser) {
      return const SizedBox.shrink();
    }

    final queryClient = useQueryClient();
    final isMutating = useState(false);
    final statusKey = QueryKeys.followStatus(
      id,
      recipientType: recipientType.apiValue,
    );

    final statusQuery = useQuery<FollowingModel?, Object>(
      statusKey,
      (_) => FollowingsService().getOutgoingEdge(
        id,
        recipientType: recipientType,
      ),
      retry: noRetry,
    );

    final edge = statusQuery.data;
    final isFollowing = edge != null && edge.isAccepted;
    final busy = isMutating.value || statusQuery.isLoading;

    Future<void> invalidateRelated() async {
      await Future.wait([
        if (recipientType == FollowRecipientType.user) ...[
          queryClient.invalidateQueries(
            queryKey: QueryKeys.publicProfile(id),
          ),
          queryClient.invalidateQueries(queryKey: QueryKeys.followers(id)),
        ],
        if (recipientType == FollowRecipientType.team) ...[
          queryClient.invalidateQueries(queryKey: QueryKeys.teamDetail(id)),
          queryClient.invalidateQueries(
            queryKey: QueryKeys.teamFollowers(id),
          ),
        ],
        if (myId != null && myId.isNotEmpty)
          queryClient.invalidateQueries(queryKey: QueryKeys.following(myId)),
      ]);
    }

    Future<void> toggle() async {
      if (isMutating.value) return;
      isMutating.value = true;
      try {
        if (isFollowing) {
          var followingId = edge.id;
          if (followingId == null || followingId.isEmpty) {
            final fresh = await FollowingsService().getOutgoingEdge(
              id,
              recipientType: recipientType,
            );
            followingId = fresh?.id;
          }
          if (followingId == null || followingId.isEmpty) return;

          final ok = await FollowingsService().unfollow(followingId);
          if (!ok) return;

          await queryClient.resetQueries(queryKey: statusKey, exact: true);
        } else {
          final created = await FollowingsService().follow(
            id,
            recipientType: recipientType,
          );
          if (created == null) return;

          queryClient.setQueryData<FollowingModel?, Object>(
            statusKey,
            (_) => created,
          );
        }

        await invalidateRelated();
      } finally {
        isMutating.value = false;
      }
    }

    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          isFollowing ? Colors.white : const Color(AppColors.primaryColor),
        ),
      ),
    );

    if (isFollowing) {
      return OutlinedButton.icon(
        onPressed: busy ? null : toggle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
        ),
        icon: busy ? spinner : const Icon(Icons.check, size: 18),
        label: const Text(
          'Following',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: busy ? null : toggle,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(AppColors.primaryColor),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
        disabledForegroundColor: const Color(AppColors.primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      icon: busy ? spinner : const Icon(Icons.person_add_alt_1, size: 18),
      label: const Text(
        'Follow',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
