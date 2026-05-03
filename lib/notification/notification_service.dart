import 'package:flutter_application_1/core/config/api_constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:flutter_application_1/core/services/api_service.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();

  /// List notifications for the current user (`ListNotificationsQueryDto`).
  Future<PaginatedResponse<AppNotification>?> list({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    NotificationModule? module,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (unreadOnly != null) {
      queryParameters['unreadOnly'] = unreadOnly ? 'true' : 'false';
    }
    if (module != null) {
      queryParameters['module'] = module.apiKey;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.notifications.base,
      queryParameters: queryParameters,
    );
    if (response == null) {
      return EmptyPaginatedResponse<AppNotification>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => AppNotification.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AppNotification?> getOne(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.notifications.byId(id),
    );
    if (response == null) return null;
    return AppNotification.fromJson(response);
  }

  Future<AppNotification?> markRead(String id) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.notifications.markRead(id),
      data: <String, dynamic>{},
    );
    if (response == null) return null;
    return AppNotification.fromJson(response);
  }

  Future<MarkAllReadResponse?> markAllRead() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.notifications.markAllRead,
    );
    if (response == null) return null;
    return MarkAllReadResponse.fromJson(response);
  }

  Future<DeleteNotificationResponse?> deleteOne(String id) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.notifications.byId(id),
    );
    if (response == null) return null;
    return DeleteNotificationResponse.fromJson(response);
  }

  Future<DeleteAllNotificationsResponse?> deleteAll() async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.notifications.deleteAll,
    );
    if (response == null) return null;
    return DeleteAllNotificationsResponse.fromJson(response);
  }
}
