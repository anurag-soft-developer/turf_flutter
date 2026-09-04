import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../components/shared/loading_overlay.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/utils/app_snackbar.dart';
import '../../engagement/engagement_entity.dart';
import '../../engagement/engagement_service.dart';
import '../model/content_post_model.dart';
import '../post_service.dart';
import 'explore_like_button.dart';

/// Full post: author, caption, media carousel, like, and owner delete.
class ContentPostCard extends StatefulWidget {
  const ContentPostCard({
    super.key,
    required this.post,
    this.popOnDelete = false,
  });

  final ContentPostModel post;

  /// When true, pops the current route after a successful delete (profile viewer).
  final bool popOnDelete;

  @override
  State<ContentPostCard> createState() => _ContentPostCardState();
}

class _ContentPostCardState extends State<ContentPostCard> {
  bool _deleting = false;

  bool get _isOwner {
    if (!Get.isRegistered<AuthStateController>()) return false;
    final userId = Get.find<AuthStateController>().user?.id;
    final authorId = widget.post.postedByHelper.getId();
    if (userId == null || authorId == null) return false;
    return userId == authorId;
  }

  Future<void> _delete() async {
    final post = widget.post;
    final id = post.id;
    if (id == null || id.isEmpty || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(AppColors.errorColor),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final ok = await PostService().delete(id);
      if (!mounted) return;
      if (!ok) {
        AppSnackbar.error(
          title: 'Failed',
          message: 'Could not delete post. Try again.',
        );
        return;
      }

      await invalidatePostQueries(
        userId: post.postedByHelper.getId(),
        postId: id,
      );
      if (widget.popOnDelete && mounted) {
        Navigator.of(context).pop();
      }
      AppSnackbar.success(
        title: 'Deleted',
        message: 'Your post was removed.',
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.postedByHelper;
    final teamName = post.teamHelper.getName();
    final match = post.match;
    final turfName = post.turfHelper.getName();
    final id = post.id ?? '';

    return VisibilityDetector(
      key: Key('post-view-$id'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.5 || id.isEmpty) return;
        EngagementService().trackView(
          entityType: EngagementEntityType.post,
          entityId: id,
        );
      },
      child: LoadingOverlay(
        isLoading: _deleting,
        message: 'Deleting…',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                if (id.isNotEmpty)
                  ExploreLikeButton(
                    entityType: EngagementEntityType.post,
                    entityId: id,
                  ),
                if (_isOwner)
                  PopupMenuButton<String>(
                    tooltip: 'Post options',
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(AppColors.textColor),
                    ),
                    onSelected: (value) {
                      if (value == 'delete') _delete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Color(AppColors.errorColor)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (post.title.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
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
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              PostMediaCarousel(media: post.media),
            ],
          ],
        ),
      ),
    );
  }
}

/// Survives [ListView] recycle so mixed-size posts keep a stable height
/// when they re-enter from the top (avoids upward-scroll jump).
class _PostMediaAspectCache {
  static final Map<String, double> ratioByUrl = {};
}

class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({super.key, required this.media});

  final List<MediaModel> media;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  static const _fallbackRatio = 1.0;
  static const _videoRatio = 16 / 9;
  static const _maxScreenHeightFraction = 0.8;

  int _pageIndex = 0;
  final Map<String, double> _aspectRatios = {};
  final List<VoidCallback> _cancelResolvers = [];
  double? _lockedHeight;
  double? _lockedWidth;

  @override
  void initState() {
    super.initState();
    _resolveMedia(widget.media);
  }

  @override
  void didUpdateWidget(PostMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.media, widget.media)) {
      _lockedHeight = null;
      _lockedWidth = null;
      _resolveMedia(widget.media);
    }
  }

  @override
  void dispose() {
    for (final cancel in _cancelResolvers) {
      cancel();
    }
    super.dispose();
  }

  void _resolveMedia(List<MediaModel> media) {
    for (final item in media) {
      if (item.kind != MediaKind.image) continue;
      final cached = _PostMediaAspectCache.ratioByUrl[item.url];
      if (cached != null) {
        _aspectRatios[item.url] = cached;
        continue;
      }
      if (_aspectRatios.containsKey(item.url)) continue;
      _listenForRatio(item.url);
    }
  }

  void _storeRatio(String url, double ratio) {
    if (_PostMediaAspectCache.ratioByUrl[url] == ratio &&
        _aspectRatios[url] == ratio) {
      return;
    }
    _PostMediaAspectCache.ratioByUrl[url] = ratio;
    _aspectRatios[url] = ratio;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _listenForRatio(String url) {
    final stream = AppNetworkImage.provider(
      url,
    ).resolve(const ImageConfiguration());
    var cancelled = false;
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        final width = info.image.width;
        final height = info.image.height;
        if (width <= 0 || height <= 0) return;
        final ratio = width / height;
        _PostMediaAspectCache.ratioByUrl[url] = ratio;
        if (cancelled || !mounted) return;
        _storeRatio(url, ratio);
      },
      onError: (_, __) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    _cancelResolvers.add(() {
      cancelled = true;
    });
  }

  double _ratioFor(MediaModel item) {
    if (item.kind == MediaKind.video) return _videoRatio;
    return _aspectRatios[item.url] ??
        _PostMediaAspectCache.ratioByUrl[item.url] ??
        _fallbackRatio;
  }

  bool _hasRatio(MediaModel item) {
    if (item.kind == MediaKind.video) return true;
    return _aspectRatios.containsKey(item.url) ||
        _PostMediaAspectCache.ratioByUrl.containsKey(item.url);
  }

  /// Tallest known file at [width], capped at 80% of screen height.
  /// Never shrinks for a given width so async decode / ListView recycle
  /// cannot collapse the item.
  double _carouselHeight(double width) {
    var maxHeight = 0.0;
    var anyKnown = false;
    for (final item in widget.media) {
      if (!_hasRatio(item)) continue;
      anyKnown = true;
      final height = width / _ratioFor(item);
      if (height > maxHeight) maxHeight = height;
    }
    final cap = MediaQuery.sizeOf(context).height * _maxScreenHeightFraction;
    final computed =
        (anyKnown ? maxHeight : width / _fallbackRatio).clamp(0.0, cap);
    if (_lockedWidth != width || _lockedHeight == null) {
      _lockedWidth = width;
      _lockedHeight = computed;
      return computed;
    }
    if (computed > _lockedHeight!) {
      _lockedHeight = computed.clamp(0.0, cap);
    }
    return _lockedHeight!.clamp(0.0, cap);
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media.isEmpty) return const SizedBox.shrink();

    final current = media[_pageIndex.clamp(0, media.length - 1)];
    final caption = current.caption?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final height = _carouselHeight(screenWidth);

            return SizedBox(
              width: constraints.maxWidth,
              height: height,
              child: OverflowBox(
                minWidth: screenWidth,
                maxWidth: screenWidth,
                minHeight: height,
                maxHeight: height,
                alignment: Alignment.center,
                child: SizedBox(
                  width: screenWidth,
                  height: height,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Colors.black,
                          child: PageView.builder(
                            itemCount: media.length,
                            onPageChanged: (index) =>
                                setState(() => _pageIndex = index),
                            itemBuilder: (context, index) {
                              final item = media[index];
                              if (item.kind == MediaKind.video) {
                                return const _VideoPlaceholder();
                              }
                              return AppNetworkImage(
                                item.url,
                                width: screenWidth,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (media.length > 1) ...[
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_pageIndex + 1}/${media.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(media.length, (index) {
                                  final active = index == _pageIndex;
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: active
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              caption,
              style: const TextStyle(
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black12,
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 44,
          color: Colors.white70,
        ),
      ),
    );
  }
}

Future<void> invalidatePostQueries({
  String? userId,
  required String postId,
}) async {
  if (!Get.isRegistered<QueryClient>()) return;
  final client = Get.find<QueryClient>();
  await Future.wait([
    client.invalidateQueries(queryKey: QueryKeys.explorePrefix),
    if (userId != null && userId.isNotEmpty)
      client.invalidateQueries(queryKey: QueryKeys.userPosts(userId)),
    client.invalidateQueries(queryKey: QueryKeys.explorePost(postId)),
  ]);
}
