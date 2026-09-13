import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import '../../core/routes/route_query.dart';
import '../model/content_post_model.dart';
import 'content_post_card.dart';
import 'explore_post_viewer_controller.dart';

Future<T?> openExplorePostViewer<T>({
  required String id,
  PostFilterQuery? filter,
  List<Object>? queryKey,
  List<ContentPostModel> seedPosts = const [],
  int seedPage = 0,
  bool seedHasNextPage = true,
}) {
  final tag = '${id}_${DateTime.now().microsecondsSinceEpoch}';
  Get.put(
    ExplorePostViewerController(
      initialPostId: id,
      filter: filter,
      seedPosts: seedPosts,
      seedPage: seedPage,
      seedHasNextPage: seedHasNextPage,
    ),
    tag: tag,
  );

  void deleteController() {
    if (Get.isRegistered<ExplorePostViewerController>(tag: tag)) {
      Get.delete<ExplorePostViewerController>(tag: tag);
    }
  }

  final nav = Get.toNamed<T>(
    AppConstants.routes.explorePost(id),
    arguments: {'controllerTag': tag},
    preventDuplicates: false,
  );
  if (nav == null) {
    deleteController();
    return Future.value();
  }
  return nav.whenComplete(deleteController);
}

class ExplorePostViewerScreen extends StatelessWidget {
  const ExplorePostViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};
    final tag = args['controllerTag'] as String?;
    if (tag != null &&
        Get.isRegistered<ExplorePostViewerController>(tag: tag)) {
      return _ExplorePostViewerBody(tag: tag);
    }

    final postId = routeParam('id');
    if (postId == null || postId.isEmpty) {
      return const _MissingPostScaffold();
    }
    return _DeepLinkPostViewer(postId: postId);
  }
}

class _DeepLinkPostViewer extends StatefulWidget {
  const _DeepLinkPostViewer({required this.postId});

  final String postId;

  @override
  State<_DeepLinkPostViewer> createState() => _DeepLinkPostViewerState();
}

class _DeepLinkPostViewerState extends State<_DeepLinkPostViewer> {
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = '${widget.postId}_deep';
    if (!Get.isRegistered<ExplorePostViewerController>(tag: _tag)) {
      Get.put(
        ExplorePostViewerController(initialPostId: widget.postId),
        tag: _tag,
      );
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<ExplorePostViewerController>(tag: _tag)) {
      Get.delete<ExplorePostViewerController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ExplorePostViewerBody(tag: _tag);
  }
}

class _ExplorePostViewerBody extends StatelessWidget {
  const _ExplorePostViewerBody({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExplorePostViewerController>(tag: tag);
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(title: const Text('Posts')),
      body: Obx(() => _feedBody(c)),
    );
  }

  Widget _feedBody(ExplorePostViewerController c) {
    if (c.isLoading.value && c.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(AppColors.primaryColor),
          ),
        ),
      );
    }

    if (c.isError.value && c.posts.isEmpty) {
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
                onPressed: c.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (c.posts.isEmpty) {
      return const Center(
        child: Text(
          'No photos yet',
          style: TextStyle(color: Color(AppColors.textSecondaryColor)),
        ),
      );
    }

    final centerIndex = c.centerIndex;
    final before = c.posts.sublist(0, centerIndex);
    final current = c.posts[centerIndex];
    final after = c.posts.sublist(centerIndex + 1);

    return CustomScrollView(
      controller: c.scrollController,
      center: c.centerKey,
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
          key: c.centerKey,
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
              childCount:
                  after.length + (c.isFetchingNextPage.value ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingPostScaffold extends StatelessWidget {
  const _MissingPostScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(title: const Text('Post')),
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
