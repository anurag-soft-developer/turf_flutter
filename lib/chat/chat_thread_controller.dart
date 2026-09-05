import 'dart:async';

import 'package:flutter_application_1/chat/chat_service.dart';
import 'package:flutter_application_1/chat/chat_socket_service.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/chat/utils/chat_inbox_cache.dart';
import 'package:flutter_application_1/chat/utils/flyer_message_mapper.dart';
import 'package:flutter_application_1/core/auth/auth_state_controller.dart';
import 'package:flutter_application_1/core/services/user_service.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

class ChatThreadController extends GetxController {
  ChatThreadController({
    required this.scope,
    required this.scopeId,
  });

  final ChatScope scope;
  final String scopeId;

  final ChatService _chatService = ChatService();
  final InMemoryChatController chatController = InMemoryChatController();
  final Map<String, User> _userCache = <String, User>{};

  final RxList<ChatReadCursor> cursors = <ChatReadCursor>[].obs;
  final RxnString seenSubtitle = RxnString();

  bool _loadingEarlier = false;
  bool _hasMore = true;

  StreamSubscription<dynamic>? _opsSub;
  StreamSubscription<ChatMessageModel>? _msgSub;
  StreamSubscription<ChatReadEvent>? _readSub;

  String get me => Get.find<AuthStateController>().user?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    _opsSub = chatController.operationsStream.listen((_) {
      _recomputeSeenSubtitle();
    });
    if (scopeId.isEmpty || me.isEmpty) return;
    if (!Get.isRegistered<ChatSocketService>()) return;
    unawaited(_startSession());
  }

  @override
  void onClose() {
    unawaited(_opsSub?.cancel());
    unawaited(_msgSub?.cancel());
    unawaited(_readSub?.cancel());
    if (Get.isRegistered<ChatSocketService>()) {
      final socket = ChatSocketService.instance;
      socket.clearActiveRoom();
      unawaited(socket.leaveRoom(scope, scopeId));
    }
    chatController.dispose();
    super.onClose();
  }

  Future<void> _startSession() async {
    final socket = ChatSocketService.instance;
    socket.setActiveRoom(scope, scopeId);
    unawaited(socket.start());
    unawaited(socket.joinRoom(scope, scopeId));
    unawaited(_loadInitial());

    _msgSub = socket.messages.listen((message) {
      if (message.scope != scope || message.scopeId != scopeId) return;
      if (chatController.messages.any((m) => m.id == message.messageId)) {
        return;
      }
      unawaited(chatController.insertMessage(toFlyerTextMessage(message)));
      if (message.senderUserId != me) {
        unawaited(_markRead());
      }
    });
    _readSub = socket.reads.listen((event) {
      if (event.scope != scope || event.scopeId != scopeId) return;
      final current = List<ChatReadCursor>.from(cursors);
      cursors.assignAll([
        for (final cursor in current)
          if (cursor.userId != event.userId) cursor,
        ChatReadCursor(userId: event.userId, lastReadAt: event.lastReadAt),
      ]);
      _recomputeSeenSubtitle();
    });
  }

  Future<void> _loadCursors() async {
    final result = await _chatService.listReadCursors(
      scope: scope,
      scopeId: scopeId,
    );
    cursors.assignAll(result);
    _recomputeSeenSubtitle();
  }

  Future<void> _markRead() async {
    ChatInboxCache.clearUnread(scope, scopeId);
    if (Get.isRegistered<ChatSocketService>() &&
        ChatSocketService.instance.isConnected) {
      ChatSocketService.instance.emitRead(scope: scope, scopeId: scopeId);
    } else {
      await _chatService.markRead(scope: scope, scopeId: scopeId);
    }
  }

  Future<void> _loadInitial() async {
    final history = await _chatService.listMessages(
      scope: scope,
      scopeId: scopeId,
      limit: 30,
    );
    _hasMore = history.length >= 30;
    await chatController.setMessages(
      history.map(toFlyerTextMessage).toList(),
    );
    await _loadCursors();
    await _markRead();
  }

  Future<void> loadEarlier() async {
    if (_loadingEarlier || !_hasMore) return;
    final oldest = chatController.messages.isEmpty
        ? null
        : chatController.messages.last;
    final before = oldest is TextMessage
        ? oldest.createdAt?.toUtc().toIso8601String()
        : null;
    if (before == null) return;
    _loadingEarlier = true;
    try {
      final older = await _chatService.listMessages(
        scope: scope,
        scopeId: scopeId,
        limit: 30,
        before: before,
      );
      if (older.length < 30) _hasMore = false;
      if (older.isEmpty) return;
      final existingIds = chatController.messages.map((m) => m.id).toSet();
      final mapped = older
          .where((item) => !existingIds.contains(item.messageId))
          .map(toFlyerTextMessage)
          .toList();
      if (mapped.isNotEmpty) {
        await chatController.insertAllMessages(
          mapped,
          index: chatController.messages.length,
        );
      }
    } finally {
      _loadingEarlier = false;
    }
  }

  Future<User?> resolveUser(String id) async {
    final cached = _userCache[id];
    if (cached != null) return cached;
    if (id == me) {
      final profile = Get.find<AuthStateController>().user;
      final user = User(
        id: id,
        name: profile?.displayName,
        imageSource: profile?.avatar,
      );
      _userCache[id] = user;
      return user;
    }
    try {
      final profile = await UserService().getPublicProfile(id);
      final user = User(
        id: id,
        name: profile?.displayName ?? 'Player',
        imageSource: profile?.avatar,
      );
      _userCache[id] = user;
      return user;
    } catch (_) {
      final user = User(id: id, name: 'Player');
      _userCache[id] = user;
      return user;
    }
  }

  void onSend(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!Get.isRegistered<ChatSocketService>() ||
        !ChatSocketService.instance.isConnected) {
      AppSnackbar.error(
        title: 'Chat',
        message: 'Not connected. Try again in a moment.',
      );
      return;
    }
    ChatSocketService.instance.sendMessage(
      scope: scope,
      scopeId: scopeId,
      body: trimmed,
    );
  }

  Future<List<String>> seenByNames() async {
    final names = <String>[];
    final own = chatController.messages.where((m) => m.authorId == me);
    final lastOwn = own.isEmpty ? null : own.first;
    final createdAt = lastOwn?.createdAt;
    for (final cursor in cursors) {
      if (cursor.userId == me) continue;
      if (createdAt != null &&
          cursor.lastReadAt.isBefore(createdAt.toUtc())) {
        continue;
      }
      final user = await resolveUser(cursor.userId);
      names.add(user?.name ?? cursor.userId);
    }
    return names;
  }

  void _recomputeSeenSubtitle() {
    if (chatController.messages.isEmpty) {
      seenSubtitle.value = null;
      return;
    }
    final own = chatController.messages.where((m) => m.authorId == me);
    if (own.isEmpty) {
      seenSubtitle.value = null;
      return;
    }
    final lastOwn = own.first;
    final createdAt = lastOwn.createdAt;
    if (createdAt == null) {
      seenSubtitle.value = null;
      return;
    }
    final seenBy = cursors
        .where(
          (cursor) =>
              cursor.userId != me &&
              !cursor.lastReadAt.isBefore(createdAt.toUtc()),
        )
        .toList();
    if (scope == ChatScope.player) {
      seenSubtitle.value = seenBy.isNotEmpty ? 'Seen' : 'Sent';
      return;
    }
    if (seenBy.isEmpty) {
      seenSubtitle.value = null;
      return;
    }
    seenSubtitle.value = 'Seen by ${seenBy.length}';
  }
}
