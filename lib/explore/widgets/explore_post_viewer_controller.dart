import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/paginated_response.dart';
import '../model/content_post_model.dart';
import '../post_service.dart';

/// Paged tagged/author feed. Fetches via [PostService] (same API as the
/// grid). Does not subscribe to the grid's infinite query, so opening this
/// route cannot rebuild NestedScrollView observers mid-build.
class ExplorePostViewerController extends GetxController {
  ExplorePostViewerController({
    required this.initialPostId,
    this.filter,
    List<ContentPostModel> seedPosts = const [],
    int seedPage = 0,
    bool seedHasNextPage = true,
  })  : _page = seedPosts.isEmpty ? 0 : seedPage,
        _hasNextPage = seedPosts.isEmpty ? true : seedHasNextPage {
    if (seedPosts.isNotEmpty) {
      posts.assignAll(seedPosts);
    }
  }

  final String initialPostId;
  PostFilterQuery? filter;

  final posts = <ContentPostModel>[].obs;
  final isLoading = false.obs;
  final isError = false.obs;
  final isFetchingNextPage = false.obs;

  final scrollController = ScrollController();
  final centerKey = GlobalKey();

  int _page;
  bool _hasNextPage;
  bool _fetching = false;
  bool _ready = false;

  bool get hasNextPage => _hasNextPage;

  int get centerIndex {
    final index = posts.indexWhere((p) => p.id == initialPostId);
    return index < 0 ? 0 : index;
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      _ready = true;
      _bootstrap();
    });
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!_ready || !scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 400) {
      fetchNextPage();
    }
  }

  void _setFlag(RxBool flag, bool value) {
    if (flag.value == value) return;
    flag.value = value;
  }

  Future<void> retry() async {
    _setFlag(isError, false);
    _page = 0;
    _hasNextPage = true;
    posts.clear();
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (filter == null) {
      await _resolveAuthorFilter();
      if (filter == null) {
        _setFlag(isError, true);
        return;
      }
    }

    if (posts.isEmpty) {
      _setFlag(isLoading, true);
      await fetchNextPage();
      _setFlag(isLoading, false);
    }

    while (posts.indexWhere((p) => p.id == initialPostId) < 0 &&
        _hasNextPage) {
      _setFlag(isLoading, true);
      final progressed = await fetchNextPage();
      if (!progressed) break;
    }
    _setFlag(isLoading, false);

    final index = posts.indexWhere((p) => p.id == initialPostId);
    if (index >= 0 && posts.length - index - 1 < 2) {
      await fetchNextPage();
    }
  }

  Future<void> _resolveAuthorFilter() async {
    try {
      final loaded = await PostService().getById(initialPostId);
      final uid = loaded?.postedByHelper.getId();
      if (uid == null || uid.isEmpty) return;
      filter = PostFilterQuery(
        postedBy: uid,
        status: PostStatus.published,
        limit: PostService.userPostsPageSize,
      );
    } catch (_) {
      filter = null;
    }
  }

  Future<bool> fetchNextPage() async {
    final currentFilter = filter;
    if (currentFilter == null || _fetching || !_hasNextPage) return false;
    _fetching = true;
    if (_page > 0) _setFlag(isFetchingNextPage, true);
    try {
      final result = await PostService().findMany(
        currentFilter.copyWith(page: _page + 1),
      );
      final page = result ?? EmptyPaginatedResponse<ContentPostModel>();
      _page = page.page;
      _hasNextPage = page.hasNextPage;
      if (page.data.isNotEmpty) {
        posts.addAll(page.data);
      }
      return page.data.isNotEmpty || _hasNextPage;
    } catch (_) {
      if (posts.isEmpty) _setFlag(isError, true);
      return false;
    } finally {
      _fetching = false;
      _setFlag(isFetchingNextPage, false);
    }
  }
}
