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

class ChatReplyTarget {
  const ChatReplyTarget({
    required this.messageId,
    required this.body,
    required this.senderUserId,
  });

  final String messageId;
  final String body;
  final String senderUserId;
}

class ChatThreadController extends GetxController {
  ChatThreadController({required this.scope, required this.scopeId});

  final ChatScope scope;
  final String scopeId;

  final ChatService _chatService = ChatService();
  final InMemoryChatController chatController = InMemoryChatController();
  final Map<String, User> _userCache = <String, User>{};

  final RxList<ChatReadCursor> cursors = <ChatReadCursor>[].obs;
  final readersByMessageId = <String, List<String>>{}.obs;
  final Rxn<ChatReplyTarget> replyTo = Rxn<ChatReplyTarget>();
  final RxnString highlightedMessageId = RxnString();
  final isLoadingInitial = true.obs;

  bool _loadingEarlier = false;
  bool _hasMore = true;
  Timer? _highlightTimer;

  StreamSubscription<dynamic>? _opsSub;
  StreamSubscription<ChatMessageModel>? _msgSub;
  StreamSubscription<ChatReadEvent>? _readSub;
  StreamSubscription<ChatMessageDeletedEvent>? _deletedSub;
  StreamSubscription<ChatReactionUpdatedEvent>? _reactionSub;

  String get me => Get.find<AuthStateController>().user?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    _opsSub = chatController.operationsStream.listen((_) {
      _recomputeSeen();
    });
    if (scopeId.isEmpty || me.isEmpty) {
      isLoadingInitial.value = false;
      return;
    }
    if (!Get.isRegistered<ChatSocketService>()) {
      isLoadingInitial.value = false;
      return;
    }
    unawaited(_startSession());
  }

  @override
  void onClose() {
    unawaited(_opsSub?.cancel());
    unawaited(_msgSub?.cancel());
    unawaited(_readSub?.cancel());
    unawaited(_deletedSub?.cancel());
    unawaited(_reactionSub?.cancel());
    _highlightTimer?.cancel();
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
      _recomputeSeen();
    });
    _deletedSub = socket.deletions.listen(_onDeleted);
    _reactionSub = socket.reactions.listen(_onReactionUpdated);
  }

  Future<void> _loadCursors() async {
    final result = await _chatService.listReadCursors(
      scope: scope,
      scopeId: scopeId,
    );
    cursors.assignAll(result);
    _recomputeSeen();
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
    isLoadingInitial.value = true;
    try {
      final history = await _chatService.listMessages(
        scope: scope,
        scopeId: scopeId,
        limit: 30,
      );
      _hasMore = history.length >= 30;
      await chatController.setMessages(
        history.reversed.map(toFlyerTextMessage).toList(),
      );
      await _loadCursors();
      await _markRead();
    } catch (_) {
      AppSnackbar.error(
        title: 'Chat',
        message: 'Could not load messages. Try again.',
      );
    } finally {
      isLoadingInitial.value = false;
    }
  }

  Future<bool> loadEarlier() async {
    if (_loadingEarlier || !_hasMore) return false;
    final oldest = chatController.messages.isEmpty
        ? null
        : chatController.messages.first;
    final before = oldest is TextMessage
        ? oldest.createdAt?.toUtc().toIso8601String()
        : null;
    if (before == null) {
      _hasMore = false;
      return false;
    }
    _loadingEarlier = true;
    try {
      final older = await _chatService.listMessages(
        scope: scope,
        scopeId: scopeId,
        limit: 30,
        before: before,
      );
      if (older.length < 30) _hasMore = false;
      if (older.isEmpty) return false;
      final existingIds = chatController.messages.map((m) => m.id).toSet();
      final mapped = older
          .where((item) => !existingIds.contains(item.messageId))
          .map(toFlyerTextMessage)
          .toList()
          .reversed
          .toList();
      if (mapped.isEmpty) {
        _hasMore = false;
        return false;
      }
      await chatController.insertAllMessages(mapped, index: 0, animated: false);
      return true;
    } finally {
      _loadingEarlier = false;
    }
  }

  Future<void> scrollToQuotedMessage(String messageId) async {
    if (messageId.isEmpty) return;
    var found = chatController.messages.any((m) => m.id == messageId);
    var pages = 0;
    while (!found && _hasMore && pages < 15) {
      pages++;
      final loaded = await loadEarlier();
      if (!loaded) break;
      found = chatController.messages.any((m) => m.id == messageId);
    }
    if (!found) {
      AppSnackbar.error(
        title: 'Chat',
        message: 'Original message is no longer available.',
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await chatController.scrollToMessage(messageId, alignment: 0.2);
    highlightedMessageId.value = messageId;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
      if (highlightedMessageId.value == messageId) {
        highlightedMessageId.value = null;
      }
    });
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

  void setReplyTo(Message message) {
    final body = message is TextMessage ? message.text : '';
    if (message.id.isEmpty || body.isEmpty) return;
    replyTo.value = ChatReplyTarget(
      messageId: message.id,
      body: body,
      senderUserId: message.authorId,
    );
  }

  void clearReply() {
    replyTo.value = null;
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
    final reply = replyTo.value;
    ChatSocketService.instance.sendMessage(
      scope: scope,
      scopeId: scopeId,
      body: trimmed,
      replyToMessageId: reply?.messageId,
    );
    clearReply();
  }

  void reactToMessage(String messageId, String emoji) {
    if (messageId.isEmpty || emoji.isEmpty) return;
    if (!Get.isRegistered<ChatSocketService>() ||
        !ChatSocketService.instance.isConnected) {
      AppSnackbar.error(
        title: 'Chat',
        message: 'Not connected. Try again in a moment.',
      );
      return;
    }
    ChatSocketService.instance.reactToMessage(
      scope: scope,
      scopeId: scopeId,
      messageId: messageId,
      emoji: emoji,
    );
  }

  Future<void> deleteMessage(String messageId) async {
    if (messageId.isEmpty) return;
    if (!Get.isRegistered<ChatSocketService>() ||
        !ChatSocketService.instance.isConnected) {
      AppSnackbar.error(
        title: 'Chat',
        message: 'Not connected. Try again in a moment.',
      );
      return;
    }
    ChatSocketService.instance.deleteMessage(
      scope: scope,
      scopeId: scopeId,
      messageId: messageId,
    );
  }

  Future<void> _onDeleted(ChatMessageDeletedEvent event) async {
    if (event.scope != scope || event.scopeId != scopeId) return;
    if (event.messageId.isEmpty) return;
    final existing = _messageById(event.messageId);
    if (existing == null) return;
    await chatController.removeMessage(existing);
    if (replyTo.value?.messageId == event.messageId) {
      clearReply();
    }
    _recomputeSeen();
  }

  Future<void> _onReactionUpdated(ChatReactionUpdatedEvent event) async {
    if (event.scope != scope || event.scopeId != scopeId) return;
    final existing = _messageById(event.messageId);
    if (existing is! TextMessage) return;
    await chatController.updateMessage(
      existing,
      withReactions(existing, event.reactions),
    );
  }

  Message? _messageById(String messageId) {
    for (final message in chatController.messages) {
      if (message.id == messageId) return message;
    }
    return null;
  }

  Future<List<String>> seenByNames([List<String>? userIds]) async {
    final ids =
        userIds ??
        readersByMessageId.values.expand((id) => id).toSet().toList();
    final names = <String>[];
    for (final id in ids) {
      if (id == me) continue;
      final user = await resolveUser(id);
      names.add(user?.name ?? id);
    }
    return names;
  }

  void _recomputeSeen() {
    final byMessage = <String, List<String>>{};
    final messages = chatController.messages;
    if (messages.isNotEmpty) {
      for (final cursor in cursors) {
        if (cursor.userId == me) continue;
        Message? lastRead;
        for (final message in messages) {
          final at = message.createdAt;
          if (at == null) continue;
          if (!cursor.lastReadAt.isBefore(at.toUtc())) {
            lastRead = message;
          } else {
            break;
          }
        }
        if (lastRead == null) continue;
        byMessage.putIfAbsent(lastRead.id, () => []).add(cursor.userId);
      }
    }
    readersByMessageId.assignAll(byMessage);
    for (final ids in byMessage.values) {
      for (final id in ids.take(3)) {
        unawaited(resolveUser(id));
      }
    }
  }
}
