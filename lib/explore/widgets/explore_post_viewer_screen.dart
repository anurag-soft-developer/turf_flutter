import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/components/query/query_async_body.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/routes/route_query.dart';
import '../model/content_post_model.dart';
import '../post_service.dart';
import 'content_post_card.dart';

Future<T?> openExplorePostViewer<T>({
  required String id,
  String? userId,
}) {
  return Get.toNamed<T>(
        AppConstants.routes.explorePost(id),
        arguments: {
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
        preventDuplicates: false,
      ) ??
      Future.value();
}

class ExplorePostViewerScreen extends StatelessWidget {
  const ExplorePostViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postId = routeParam('id');
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    final userIdArg = (args['userId'] as String?)?.trim();

    if (postId == null || postId.isEmpty) {
      return const _MissingPostScaffold();
    }

    if (userIdArg != null && userIdArg.isNotEmpty) {
      return _AuthorPostsFeed(userId: userIdArg, initialPostId: postId);
    }

    return _ResolveAuthorThenFeed(postId: postId);
  }
}

class _ResolveAuthorThenFeed extends HookWidget {
  const _ResolveAuthorThenFeed({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final postQuery = useQuery<ContentPostModel, Object>(
      QueryKeys.explorePost(postId),
      (_) async {
        final loaded = await PostService().getById(postId);
        if (loaded == null) throw Exception('Could not load post.');
        return loaded;
      },
      retry: noRetry,
    );

    final post = postQuery.data;
    final uid = post?.postedByHelper.getId();
    if (post != null && uid != null && uid.isNotEmpty) {
      return _AuthorPostsFeed(userId: uid, initialPostId: postId);
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Post')),
      body: QueryAsyncBody<ContentPostModel, Object>(
        state: postQuery,
        onRetry: () => postQuery.refetch(),
        data: (loaded) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: ContentPostCard(post: loaded, popOnDelete: true),
        ),
      ),
    );
  }
}

class _MissingPostScaffold extends StatelessWidget {
  const _MissingPostScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: const Text('Post')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Post not found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorPostsFeed extends HookWidget {
  const _AuthorPostsFeed({
    required this.userId,
    required this.initialPostId,
  });

  final String userId;
  final String initialPostId;

  @override
  Widget build(BuildContext context) {
    final centerKey = useMemoized(() => GlobalKey(), [initialPostId]);
    final scrollController = useScrollController();

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

    final posts =
        query.data?.pages.expand((p) => p.data).toList() ??
        const <ContentPostModel>[];
    final index = posts.indexWhere((p) => p.id == initialPostId);
    final locating = index < 0 && (query.hasNextPage || query.isFetching);

    useEffect(() {
      if (index >= 0) return null;
      if (query.hasNextPage && !query.isFetchingNextPage && !query.isLoading) {
        query.fetchNextPage();
      }
      return null;
    }, [index, posts.length, query.hasNextPage, query.isFetchingNextPage]);

    final queryRef = useRef(query);
    queryRef.value = query;

    useEffect(() {
      void onScroll() {
        final q = queryRef.value;
        if (!scrollController.hasClients) return;
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 400) {
          if (q.hasNextPage && !q.isFetchingNextPage) {
            q.fetchNextPage();
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    useEffect(() {
      if (index < 0) return null;
      final remainingAfter = posts.length - index - 1;
      if (remainingAfter < 2 &&
          query.hasNextPage &&
          !query.isFetchingNextPage) {
        query.fetchNextPage();
      }
      return null;
    }, [index, posts.length, query.hasNextPage, query.isFetchingNextPage]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: _feedBody(
        query: query,
        posts: posts,
        index: index,
        locating: locating,
        centerKey: centerKey,
        scrollController: scrollController,
      ),
    );
  }

  Widget _feedBody({
    required InfiniteQueryResult<PaginatedResponse<ContentPostModel>, Object,
            int>
        query,
    required List<ContentPostModel> posts,
    required int index,
    required bool locating,
    required GlobalKey centerKey,
    required ScrollController scrollController,
  }) {
    if (query.isLoading || (query.isFetching && posts.isEmpty) || locating) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (query.isError && posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load posts',
                style: TextStyle(color: Color(AppColors.textSecondaryColor)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => query.refetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'No photos yet',
          style: TextStyle(color: Color(AppColors.textSecondaryColor)),
        ),
      );
    }

    final centerIndex = index < 0 ? 0 : index;
    final before = posts.sublist(0, centerIndex);
    final current = posts[centerIndex];
    final after = posts.sublist(centerIndex + 1);

    return CustomScrollView(
      controller: scrollController,
      center: centerKey,
      slivers: [
        if (before.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final post = before[before.length - 1 - i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ContentPostCard(post: post, popOnDelete: true),
                  );
                },
                childCount: before.length,
              ),
            ),
          ),
        SliverPadding(
          key: centerKey,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ContentPostCard(post: current, popOnDelete: true),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i == after.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ContentPostCard(post: after[i], popOnDelete: true),
                );
              },
              childCount: after.length + (query.isFetchingNextPage ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}
