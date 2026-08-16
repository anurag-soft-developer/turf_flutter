import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';
import 'model/content_post_model.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final ApiService _apiService = ApiService();

  Future<ContentPostModel?> getById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.posts.byId(id),
    );
    if (response == null) return null;
    return ContentPostModel.fromJson(response);
  }
}
