import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'model/content_post_model.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  static const userPostsPageSize = 12;

  final ApiService _apiService = ApiService();

  Future<ContentPostModel?> getById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.posts.byId(id),
    );
    if (response == null) return null;
    return ContentPostModel.fromJson(response);
  }

  Future<ContentPostModel?> create(CreatePostRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.posts.list,
      data: request.toJson(),
    );
    if (response == null) return null;
    return ContentPostModel.fromJson(response);
  }

  Future<bool> delete(String id) {
    return _apiService.deleteResource(ApiConstants.posts.byId(id));
  }

  Future<PaginatedResponse<ContentPostModel>?> findMany(
    PostFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.posts.list,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<ContentPostModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => ContentPostModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
