import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';

import '../../components/shared/app_network_image.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../explore/model/content_post_model.dart';
import '../../explore/post_service.dart';
import '../../explore/widgets/explore_post_viewer_screen.dart';

/// 3-column published-post thumbnail grid for a user's profile Photos tab.
///
/// Returns slivers for a page-level [CustomScrollView]. Page refresh owns
/// pull-to-refresh; this widget only paginates on scroll.
class ProfilePostsGrid extends HookWidget {
  const ProfilePostsGrid({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query =
        useInfiniteQuery<PaginatedResponse<ContentPostModel>, Object, int>(
      QueryKeys.userPosts(userId),
      (ctx) async {
        final result = await PostService().findMany(
          PostFilterQuery(
            postedBy: userId,
            status: PostStatus.published,
            page: ctx.pageParam,
            limit: PostService.userPostsPageSize,
          ),
        );
        return result ?? EmptyPaginatedResponse<ContentPostModel>();
      },
      initialPageParam: 1,
      retry: noRetry,
      nextPageParamBuilder: (data) {
        final last = data.pages.isNotEmpty ? data.pages.last : null;
        if (last == null || !last.hasNextPage) return null;
        return last.page + 1;
      },
    );

    final queryRef = useRef(query);
    queryRef.value = query;

    useEffect(() {
      var cancelled = false;
      ScrollPosition? position;

      void onScroll() {
        final q = queryRef.value;
        if (position == null || !position!.hasPixels) return;
        if (position!.pixels >= position!.maxScrollExtent - 200) {
          if (q.hasNextPage && !q.isFetchingNextPage) {
            q.fetchNextPage();
          }
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cancelled || !context.mounted) return;
        position = Scrollable.maybeOf(context)?.position;
        position?.addListener(onScroll);
      });

      return () {
        cancelled = true;
        position?.removeListener(onScroll);
      };
    }, const []);

    final posts =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <ContentPostModel>[];

    if (query.isLoading || (query.isFetching && posts.isEmpty)) {
      return const _StatusSliver(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && posts.isEmpty) {
      return _StatusSliver(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Color(AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'Failed to load photos',
              style: TextStyle(
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

    if (posts.isEmpty) {
      return const _StatusSliver(
        child: Text(
          'No photos yet',
          style: TextStyle(
            color: Color(AppColors.textSecondaryColor),
            fontSize: 14,
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                final thumb = post.primaryMedia?.url;
                final id = post.id;

                return GestureDetector(
                  onTap: () {
                    if (id != null && id.isNotEmpty) {
                      openExplorePostViewer(id: id, userId: userId);
                    }
                  },
                  child: thumb == null || thumb.isEmpty
                      ? Container(
                          color: Colors.black12,
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        )
                      : AppNetworkImage(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.black12,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                        ),
                );
              },
              childCount: posts.length,
            ),
          ),
        ),
        if (query.isFetchingNextPage)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusSliver extends StatelessWidget {
  const _StatusSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(child: child),
      ),
    );
  }
}
