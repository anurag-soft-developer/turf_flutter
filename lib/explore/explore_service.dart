import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';
import 'model/explore_category.dart';
import 'model/explore_filters.dart';
import 'model/explore_item.dart';

class ExploreService {
  static final ExploreService _instance = ExploreService._internal();
  factory ExploreService() => _instance;
  ExploreService._internal();

  final ApiService _apiService = ApiService();

  Future<ExplorePaginatedResponse?> fetch({
    String? q,
    ExploreCategory category = ExploreCategory.all,
    String view = 'feed',
    int page = 1,
    int limit = 20,
    ExploreFilters filters = ExploreFilters.all,
  }) async {
    final params = <String, dynamic>{
      'category': category.apiValue,
      'view': view,
      'page': page,
      'limit': limit,
      ...filters.toQueryParameters(),
    };

    final trimmed = q?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      params['q'] = trimmed;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.explore.base,
      queryParameters: params,
    );

    if (response == null) {
      return ExplorePaginatedResponse(
        data: const [],
        totalDocuments: 0,
        page: page,
        limit: limit,
        totalPages: 0,
      );
    }

    return ExplorePaginatedResponse.fromJson(response);
  }
}
