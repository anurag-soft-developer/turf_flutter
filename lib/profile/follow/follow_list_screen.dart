import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/player/follow/user_list_tile.dart';
import '../../core/config/constants.dart';
import '../../core/models/following/following_model.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/services/followings_service.dart';

enum FollowListMode { followers, following, teamFollowers }

/// Thin route wrapper — `/followers/:userId`.
class FollowersScreen extends StatelessWidget {
  const FollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FollowListScreen(mode: FollowListMode.followers);
  }
}

/// Thin route wrapper — `/following/:userId`.
class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FollowListScreen(mode: FollowListMode.following);
  }
}

/// Thin route wrapper — `/team-followers/:teamId`.
class TeamFollowersScreen extends StatelessWidget {
  const TeamFollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FollowListScreen(mode: FollowListMode.teamFollowers);
  }
}

/// Paginated followers/following list.
///
/// Routes:
/// - `/followers/:userId`
/// - `/following/:userId`
/// - `/team-followers/:teamId`
///
/// Optional `name` query parameter for the app bar title.
class FollowListScreen extends HookWidget {
  const FollowListScreen({super.key, required this.mode});

  final FollowListMode mode;

  String? _parseParam(String key) {
    final value = Get.parameters[key];
    if (value != null && value.isNotEmpty) return value;
    return null;
  }

  bool get _isFollowers =>
      mode == FollowListMode.followers || mode == FollowListMode.teamFollowers;

  bool get _isTeam => mode == FollowListMode.teamFollowers;

  @override
  Widget build(BuildContext context) {
    final subjectId = useMemoized(
      () => _parseParam(_isTeam ? 'teamId' : 'userId'),
    );
    final name = useMemoized(() => _parseParam('name'));

    final title = _isFollowers ? 'Followers' : 'Following';

    if (subjectId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text(_isTeam ? 'Team not found' : 'User not found'),
        ),
      );
    }

    final query =
        useInfiniteQuery<PaginatedResponse<FollowingModel>, Object, int>(
          switch (mode) {
            FollowListMode.followers => QueryKeys.followers(subjectId),
            FollowListMode.following => QueryKeys.following(subjectId),
            FollowListMode.teamFollowers =>
              QueryKeys.teamFollowers(subjectId),
          },
          (ctx) async {
            final service = FollowingsService();
            final result = switch (mode) {
              FollowListMode.followers => await service.getFollowers(
                subjectId,
                page: ctx.pageParam,
                limit: 20,
              ),
              FollowListMode.following => await service.getFollowing(
                subjectId,
                page: ctx.pageParam,
                limit: 20,
              ),
              FollowListMode.teamFollowers => await service.getTeamFollowers(
                subjectId,
                page: ctx.pageParam,
                limit: 20,
              ),
            };
            return result ?? EmptyPaginatedResponse<FollowingModel>();
          },
          initialPageParam: 1,
          retry: noRetry,
          nextPageParamBuilder: (data) {
            final last = data.pages.isNotEmpty ? data.pages.last : null;
            if (last == null || !last.hasNextPage) return null;
            return last.page + 1;
          },
        );

    final items =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <FollowingModel>[];

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(name != null && name.isNotEmpty ? '$name — $title' : title),
      ),
      body: _buildBody(query, items),
    );
  }

  Widget _buildBody(
    InfiniteQueryResult<PaginatedResponse<FollowingModel>, Object, int> query,
    List<FollowingModel> items,
  ) {
    if (query.isLoading || (query.isFetching && items.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              _isFollowers
                  ? 'Failed to load followers'
                  : 'Failed to load following',
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => query.refetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowers
                  ? Icons.people_outline
                  : Icons.person_search_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _isFollowers ? 'No followers yet.' : 'Not following anyone yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => query.refetch(),
      color: const Color(AppColors.primaryColor),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 160) {
            if (query.hasNextPage && !query.isFetchingNextPage) {
              query.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final edge in items)
              UserListTile(
                // Follower rows show who follows; following rows show who is followed.
                helper: _isFollowers
                    ? edge.requesterHelper
                    : edge.recipientHelper,
              ),
            if (query.isFetchingNextPage)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
