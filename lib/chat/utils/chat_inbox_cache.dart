import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/core/auth/auth_state_controller.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/query/query_keys.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

class ChatInboxCache {
  ChatInboxCache._();

  static QueryClient? get _client {
    if (!Get.isRegistered<QueryClient>()) return null;
    return Get.find<QueryClient>();
  }

  static void applyUpdated(
    Map<String, dynamic> payload, {
    required bool viewing,
  }) {
    final incoming = ChatInboxItem.fromInboxUpdated(payload);
    if (incoming.scopeId.isEmpty) return;

    final me = Get.isRegistered<AuthStateController>()
        ? Get.find<AuthStateController>().user?.id
        : null;
    final sentByMe = me != null && incoming.lastSenderUserId == me;
    final bumpUnread = !viewing && !sentByMe;

    final client = _client;
    if (client == null) return;

    client.setQueryData<
        InfiniteData<PaginatedResponse<ChatInboxItem>, int>,
        Object>(
      QueryKeys.chatInbox,
      (previous) {
        if (previous == null || previous.pages.isEmpty) {
          return InfiniteData(
            [
              PaginatedResponse<ChatInboxItem>(
                data: [
                  incoming.copyWith(unreadCount: bumpUnread ? 1 : 0),
                ],
                totalDocuments: 1,
                page: 1,
                limit: 20,
                totalPages: 1,
              ),
            ],
            [1],
          );
        }

        ChatInboxItem? existing;
        for (final page in previous.pages) {
          for (final item in page.data) {
            if (item.roomKey == incoming.roomKey) {
              existing = item;
              break;
            }
          }
        }

        final nextItem = incoming.copyWith(
          title: existing?.title,
          imageUrl: existing?.imageUrl,
          unreadCount: bumpUnread
              ? (existing?.unreadCount ?? 0) + 1
              : viewing
                  ? 0
                  : existing?.unreadCount ?? 0,
        );

        final without = previous.pages
            .map(
              (page) => page.copyWith(
                data: page.data
                    .where((item) => item.roomKey != incoming.roomKey)
                    .toList(),
              ),
            )
            .toList();
        final first = without.isNotEmpty
            ? without.first
            : PaginatedResponse<ChatInboxItem>(
                data: const [],
                totalDocuments: 0,
                page: 1,
                limit: 20,
                totalPages: 1,
              );
        final insertedFirst = first.copyWith(
          data: [nextItem, ...first.data],
          totalDocuments: existing == null
              ? first.totalDocuments + 1
              : first.totalDocuments,
        );

        return InfiniteData(
          [insertedFirst, ...without.skip(1)],
          previous.pageParams,
        );
      },
    );
  }

  static void applyLastMessage(ChatInboxItem incoming) {
    if (incoming.scopeId.isEmpty) return;
    if (incoming.lastMessageId.isEmpty) {
      remove(incoming.scope, incoming.scopeId);
      return;
    }

    final client = _client;
    if (client == null) return;

    client.setQueryData<
        InfiniteData<PaginatedResponse<ChatInboxItem>, int>,
        Object>(
      QueryKeys.chatInbox,
      (previous) {
        if (previous == null) return previous;
        var found = false;
        final pages = previous.pages
            .map(
              (page) => page.copyWith(
                data: page.data.map((item) {
                  if (item.roomKey != incoming.roomKey) return item;
                  found = true;
                  return item.copyWith(
                    lastMessageId: incoming.lastMessageId,
                    lastMessageBody: incoming.lastMessageBody,
                    lastSenderUserId: incoming.lastSenderUserId,
                    lastMessageAt: incoming.lastMessageAt,
                  );
                }).toList(),
              ),
            )
            .toList();
        if (!found) return previous;
        return InfiniteData(pages, previous.pageParams);
      },
    );
  }

  static void clearUnread(ChatScope scope, String scopeId) {
    final client = _client;
    if (client == null) return;
    final key = chatRoomKey(scope, scopeId);
    client.setQueryData<
        InfiniteData<PaginatedResponse<ChatInboxItem>, int>,
        Object>(
      QueryKeys.chatInbox,
      (previous) {
        if (previous == null) return previous;
        return InfiniteData(
          previous.pages
              .map(
                (page) => page.copyWith(
                  data: page.data
                      .map(
                        (item) => item.roomKey == key
                            ? item.copyWith(unreadCount: 0)
                            : item,
                      )
                      .toList(),
                ),
              )
              .toList(),
          previous.pageParams,
        );
      },
    );
  }

  static void remove(ChatScope scope, String scopeId) {
    removeKeys({chatRoomKey(scope, scopeId)});
  }

  static void removeKeys(Set<String> keys) {
    if (keys.isEmpty) return;
    final client = _client;
    if (client == null) return;
    client.setQueryData<
        InfiniteData<PaginatedResponse<ChatInboxItem>, int>,
        Object>(
      QueryKeys.chatInbox,
      (previous) {
        if (previous == null) return previous;
        var removed = 0;
        final pages = previous.pages
            .map(
              (page) => page.copyWith(
                data: page.data.where((item) {
                  if (!keys.contains(item.roomKey)) return true;
                  removed++;
                  return false;
                }).toList(),
              ),
            )
            .toList();
        if (removed > 0 && pages.isNotEmpty) {
          pages[0] = pages[0].copyWith(
            totalDocuments: (pages[0].totalDocuments - removed)
                .clamp(0, pages[0].totalDocuments),
          );
        }
        return InfiniteData(pages, previous.pageParams);
      },
    );
  }

  static Future<void> invalidate() async {
    final client = _client;
    if (client == null) return;
    await client.invalidateQueries(queryKey: QueryKeys.chatInbox);
  }
}
