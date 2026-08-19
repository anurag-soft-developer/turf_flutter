import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../core/components/query/query_async_body.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../../core/routes/route_query.dart';
import '../../engagement/engagement_entity.dart';
import '../../engagement/engagement_service.dart';
import '../model/content_post_model.dart';
import '../post_service.dart';
import 'explore_like_button.dart';

Future<T?> openExplorePostViewer<T>({required String id}) {
  return Get.toNamed<T>(
        AppConstants.routes.explorePost(id),
        preventDuplicates: false,
      ) ??
      Future.value();
}

class ExplorePostViewerScreen extends HookWidget {
  const ExplorePostViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postId = routeParam('id');

    if (postId == null || postId.isEmpty) {
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

    useEffect(() {
      EngagementService().trackView(
        entityType: EngagementEntityType.post,
        entityId: postId,
      );
      return null;
    }, [postId]);

    final postQuery = useQuery<ContentPostModel, Object>(
      QueryKeys.explorePost(postId),
      (_) async {
        final loaded = await PostService().getById(postId);
        if (loaded == null) throw Exception('Could not load post.');
        return loaded;
      },
      retry: noRetry,
    );

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(
          postQuery.data?.title.isNotEmpty == true
              ? postQuery.data!.title
              : 'Post',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          ExploreLikeButton(
            entityType: EngagementEntityType.post,
            entityId: postId,
          ),
        ],
      ),
      body: QueryAsyncBody<ContentPostModel, Object>(
        state: postQuery,
        onRetry: () => postQuery.refetch(),
        data: (post) => _ExplorePostViewerBody(post: post),
      ),
    );
  }
}

class _ExplorePostViewerBody extends StatelessWidget {
  const _ExplorePostViewerBody({required this.post});

  final ContentPostModel post;

  @override
  Widget build(BuildContext context) {
    final author = post.postedByHelper;
    final teamName = post.teamHelper.getName();
    final match = post.match;
    final turfName = post.turfHelper.getName();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (author.getAvatar() ?? '').isNotEmpty
                  ? AppNetworkImage.provider(author.getAvatar()!)
                  : null,
              child: (author.getAvatar() ?? '').isEmpty
                  ? Text(
                      author.getDisplayName().isNotEmpty
                          ? author.getDisplayName()[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.getDisplayName(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  if (teamName != null)
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (post.title.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textColor),
            ),
          ),
        ],
        if (post.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(AppColors.textColor),
            ),
          ),
        ],
        if (match != null || turfName != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (match != null)
                Chip(
                  avatar: const Icon(Icons.sports, size: 16),
                  label: Text(match.versusLabel),
                ),
              if (turfName != null)
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text(turfName),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        for (final media in post.media) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: media.kind == MediaKind.video
                ? _VideoPlaceholder(caption: media.caption)
                : AppNetworkImage(
                    media.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 180,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
          ),
          if (media.caption != null && media.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: Text(
                media.caption!,
                style: const TextStyle(
                  color: Color(AppColors.textSecondaryColor),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({this.caption});

  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Colors.black12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, size: 44),
          if (caption != null && caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(caption!),
            ),
        ],
      ),
    );
  }
}
