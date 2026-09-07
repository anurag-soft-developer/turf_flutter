import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/core/config/api_constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/services/api_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _apiService = ApiService();

  Future<PaginatedResponse<ChatInboxItem>?> listInbox({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      queryParameters['search'] = trimmedSearch;
    }
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.chat.inbox,
      queryParameters: queryParameters,
    );
    if (response == null) {
      return EmptyPaginatedResponse<ChatInboxItem>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => ChatInboxItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<ChatMessageModel>> listMessages({
    required ChatScope scope,
    required String scopeId,
    int limit = 30,
    String? before,
  }) async {
    final queryParameters = <String, dynamic>{
      'scope': scope.apiValue,
      'scopeId': scopeId,
      'limit': limit,
    };
    if (before != null && before.isNotEmpty) {
      queryParameters['before'] = before;
    }
    final response = await _apiService.get<dynamic>(
      ApiConstants.chat.messages,
      queryParameters: queryParameters,
    );
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map(
          (item) => ChatMessageModel.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => item.messageId.isNotEmpty)
        .toList();
  }

  Future<ChatReadEvent?> markRead({
    required ChatScope scope,
    required String scopeId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.chat.read,
      data: {
        'scope': scope.apiValue,
        'scopeId': scopeId,
      },
    );
    if (response == null) return null;
    return ChatReadEvent.fromJson(response);
  }

  Future<List<ChatReadCursor>> listReadCursors({
    required ChatScope scope,
    required String scopeId,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.chat.readCursors,
      queryParameters: {
        'scope': scope.apiValue,
        'scopeId': scopeId,
      },
    );
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map(
          (item) => ChatReadCursor.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }

  Future<bool> hideThreads(List<ChatInboxItem> items) {
    return _hideThreadRefs(
      items.map((item) => (scope: item.scope, scopeId: item.scopeId)),
    );
  }

  Future<bool> _hideThreadRefs(
    Iterable<({ChatScope scope, String scopeId})> refs,
  ) async {
    final unique = <String, ({ChatScope scope, String scopeId})>{};
    for (final ref in refs) {
      if (ref.scopeId.isEmpty) continue;
      unique['${ref.scope.apiValue}:${ref.scopeId}'] = ref;
    }
    final threads = unique.values.toList();
    if (threads.isEmpty) return false;

    const batchSize = 100;
    for (var i = 0; i < threads.length; i += batchSize) {
      final end =
          i + batchSize > threads.length ? threads.length : i + batchSize;
      final batch = threads.sublist(i, end);
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.chat.hide,
        data: {
          'items': [
            for (final item in batch)
              {
                'scope': item.scope.apiValue,
                'scopeId': item.scopeId,
              },
          ],
        },
      );
      if (response == null) return false;
    }
    return true;
  }
}
