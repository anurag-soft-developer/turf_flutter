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

/// Self-contained follow/unfollow pill for the profile hero.
///
/// Hides itself when [targetUserId] is empty or is the logged-in user.
class FollowButton extends HookWidget {
  const FollowButton({super.key, required this.targetUserId});

  final String? targetUserId;

  @override
  Widget build(BuildContext context) {
    final userId = targetUserId;
    final myId = Get.isRegistered<AuthStateController>()
        ? AuthStateController.instance.user?.id
        : null;

    if (userId == null || userId.isEmpty || userId == myId) {
      return const SizedBox.shrink();
    }

    final queryClient = useQueryClient();
    final isMutating = useState(false);

    final statusQuery = useQuery<FollowingModel?, Object>(
      QueryKeys.followStatus(userId),
      (_) => FollowingsService().getOutgoingEdge(userId),
      retry: noRetry,
    );

    final edge = statusQuery.data;
    final isFollowing = edge != null && edge.isAccepted;
    final busy = isMutating.value || statusQuery.isLoading;

    Future<void> toggle() async {
      if (isMutating.value) return;
      isMutating.value = true;
      try {
        if (isFollowing) {
          final followingId = edge.id;
          if (followingId != null && followingId.isNotEmpty) {
            await FollowingsService().unfollow(followingId);
          }
        } else {
          await FollowingsService().follow(userId);
        }
        await Future.wait([
          queryClient.invalidateQueries(
            queryKey: QueryKeys.followStatus(userId),
          ),
          queryClient.invalidateQueries(
            queryKey: QueryKeys.publicProfile(userId),
          ),
          queryClient.invalidateQueries(queryKey: QueryKeys.followers(userId)),
          if (myId != null && myId.isNotEmpty)
            queryClient.invalidateQueries(queryKey: QueryKeys.following(myId)),
        ]);
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
