import '../config/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/user/user_model.dart';
import 'api_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiService _apiService = ApiService();

  Future<UserModel?> updateNotificationSettings({
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (emailNotificationsEnabled != null) {
      data['emailNotificationsEnabled'] = emailNotificationsEnabled;
    }
    if (smsNotificationsEnabled != null) {
      data['smsNotificationsEnabled'] = smsNotificationsEnabled;
    }
    if (data.isEmpty) return null;

    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.user.notificationSettings,
      data: data,
    );
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<PaginatedResponse<UserModel>?> searchPublicProfiles({
    String? query,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.user.publicProfiles,
      queryParameters: {'query': query, 'page': page, 'limit': limit},
    );
    if (response == null) {
      return EmptyPaginatedResponse<UserModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<UserModel?> getPublicProfile(String identifier) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.user.publicProfileByIdentifier(identifier),
    );
    if (response == null) return null;
    return UserModel.fromJson(response);
  }
}
