import 'package:get/get.dart';

import '../../core/models/paginated_response.dart';
import '../model/turf_review_model.dart';
import 'turf_review_service.dart';

String turfReviewsPreviewTag(String turfId) => 'turf_reviews_preview_$turfId';

String turfReviewsFullTag(String turfId) => 'turf_reviews_full_$turfId';

void reloadTurfReviewListsIfRegistered(String turfId) {
  final previewTag = turfReviewsPreviewTag(turfId);
  if (Get.isRegistered<TurfReviewsListController>(tag: previewTag)) {
    Get.find<TurfReviewsListController>(tag: previewTag).reload();
  }
  final fullTag = turfReviewsFullTag(turfId);
  if (Get.isRegistered<TurfReviewsListController>(tag: fullTag)) {
    Get.find<TurfReviewsListController>(tag: fullTag).reload();
  }
}

class TurfReviewsListController extends GetxController {
  TurfReviewsListController({
    required this.turfId,
    this.previewOnly = false,
    this.previewLimit = 3,
    this.previewSortBy = 'helpfulVotes',
  });

  final String turfId;
  final bool previewOnly;
  final int previewLimit;
  final String previewSortBy;

  final TurfReviewService _service = TurfReviewService();

  final Rxn<TurfReviewStats> stats = Rxn<TurfReviewStats>();
  final RxList<TurfReviewModel> reviews = <TurfReviewModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString errorMessage = RxnString();

  int _currentPage = 1;
  int _totalPages = 1;

  static const int _fullPageLimit = 20;

  int get _limit => previewOnly ? previewLimit : _fullPageLimit;

  String get _sortBy => previewOnly ? previewSortBy : 'createdAt';

  bool get canLoadMore =>
      !previewOnly && _currentPage < _totalPages && !isLoadingMore.value;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    errorMessage.value = null;
    _currentPage = 1;
    _totalPages = 1;
    try {
      final statsFuture = _service.getTurfReviewStats(turfId);
      final query = TurfReviewListQuery(
        turf: turfId,
        page: 1,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: 'desc',
      );
      final pageFuture = _service.findTurfReviews(turfId, query);
      final results = await Future.wait<Object?>([statsFuture, pageFuture]);
      stats.value = results[0] as TurfReviewStats?;
      final page = results[1] as PaginatedResponse<TurfReviewModel>?;
      if (page != null) {
        reviews.assignAll(page.data);
        _currentPage = page.page;
        _totalPages = page.totalPages;
      } else {
        reviews.clear();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => loadInitial();

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final query = TurfReviewListQuery(
        turf: turfId,
        page: nextPage,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: 'desc',
      );
      final page = await _service.findTurfReviews(turfId, query);
      if (page != null && page.data.isNotEmpty) {
        reviews.addAll(page.data);
        _currentPage = page.page;
        _totalPages = page.totalPages;
      }
    } finally {
      isLoadingMore.value = false;
    }
  }
}
