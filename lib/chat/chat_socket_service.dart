import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/chat/utils/chat_inbox_cache.dart';
import 'package:flutter_application_1/chat/model/chat_models.dart';
import 'package:flutter_application_1/chat/model/chat_scope.dart';
import 'package:flutter_application_1/core/config/env_config.dart';
import 'package:flutter_application_1/core/services/auth_storage_service.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService extends GetxService {
  static ChatSocketService get instance => Get.find();

  final AuthStorageService _authStorage = AuthStorageService();

  io.Socket? _socket;
  bool _started = false;
  String? _activeRoomKey;
  final Map<String, int> _joinCounts = <String, int>{};

  final StreamController<ChatMessageModel> _messagesController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<ChatReadEvent> _readsController =
      StreamController<ChatReadEvent>.broadcast();
  final StreamController<ChatMessageDeletedEvent> _deletedController =
      StreamController<ChatMessageDeletedEvent>.broadcast();

  Stream<ChatMessageModel> get messages => _messagesController.stream;
  Stream<ChatReadEvent> get reads => _readsController.stream;
  Stream<ChatMessageDeletedEvent> get deletions => _deletedController.stream;

  bool get isConnected => _socket?.connected == true;

  void setActiveRoom(ChatScope scope, String scopeId) {
    _activeRoomKey = chatRoomKey(scope, scopeId);
  }

  void clearActiveRoom() {
    _activeRoomKey = null;
  }

  bool isViewing(ChatScope scope, String scopeId) =>
      _activeRoomKey == chatRoomKey(scope, scopeId);

  Future<void> start() async {
    if (_started && _socket != null) return;

    final baseUrl = EnvConfig.realtimeWsUrl.trim();
    if (baseUrl.isEmpty) {
      debugPrint('ChatSocketService: REALTIME_WS_URL empty; chat live disabled');
      return;
    }

    final token = await _authStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('ChatSocketService: no access token; skip connect');
      return;
    }

    await disconnect();
    _started = true;

    final url = baseUrl.endsWith('/')
        ? '${baseUrl.substring(0, baseUrl.length - 1)}/chat'
        : '$baseUrl/chat';

    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(EnvConfig.realtimeSocketPath)
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('ChatSocketService: connected');
      for (final entry in _joinCounts.entries) {
        if (entry.value <= 0) continue;
        final parts = entry.key.split(':');
        if (parts.length < 2) continue;
        final scope = ChatScope.fromApi(parts.first);
        if (scope == null) continue;
        socket.emit('chat.join', {
          'scope': scope.apiValue,
          'scopeId': parts.sublist(1).join(':'),
        });
      }
    });

    socket.onDisconnect((_) {
      debugPrint('ChatSocketService: disconnected');
    });

    socket.onConnectError((error) {
      debugPrint('ChatSocketService: connect error $error');
    });

    socket.on('chat.message', (dynamic raw) {
      try {
        final map = _asStringKeyedMap(raw);
        if (map == null) return;
        final message = ChatMessageModel.fromJson(map);
        if (message.messageId.isEmpty) return;
        _messagesController.add(message);
      } catch (e, st) {
        debugPrint('chat.message handle failed: $e\n$st');
      }
    });

    socket.on('chat.inbox.updated', (dynamic raw) {
      try {
        final map = _asStringKeyedMap(raw);
        if (map == null) return;
        ChatInboxCache.applyUpdated(
          map,
          viewing: isViewing(
            ChatScope.fromApi(map['scope']?.toString()) ?? ChatScope.player,
            map['scopeId']?.toString() ?? '',
          ),
        );
      } catch (e, st) {
        debugPrint('chat.inbox.updated handle failed: $e\n$st');
      }
    });

    socket.on('chat.read', (dynamic raw) {
      try {
        final map = _asStringKeyedMap(raw);
        if (map == null) return;
        _readsController.add(ChatReadEvent.fromJson(map));
      } catch (e, st) {
        debugPrint('chat.read handle failed: $e\n$st');
      }
    });

    socket.on('chat.message.deleted', (dynamic raw) {
      try {
        final map = _asStringKeyedMap(raw);
        if (map == null) return;
        final event = ChatMessageDeletedEvent.fromJson(map);
        if (event.messageId.isEmpty) return;
        _applyDeletedInbox(event);
        _deletedController.add(event);
      } catch (e, st) {
        debugPrint('chat.message.deleted handle failed: $e\n$st');
      }
    });

    _socket = socket;
    socket.connect();
  }

  Future<void> joinRoom(ChatScope scope, String scopeId) async {
    final key = chatRoomKey(scope, scopeId);
    await start();
    final next = (_joinCounts[key] ?? 0) + 1;
    _joinCounts[key] = next;
    if (next != 1) return;
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('chat.join', {
      'scope': scope.apiValue,
      'scopeId': scopeId,
    });
  }

  Future<void> leaveRoom(ChatScope scope, String scopeId) async {
    final key = chatRoomKey(scope, scopeId);
    final current = _joinCounts[key] ?? 0;
    if (current <= 0) return;
    final next = current - 1;
    if (next > 0) {
      _joinCounts[key] = next;
      return;
    }
    _joinCounts.remove(key);
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('chat.leave', {
      'scope': scope.apiValue,
      'scopeId': scopeId,
    });
  }

  void sendMessage({
    required ChatScope scope,
    required String scopeId,
    required String body,
    String? clientMessageId,
  }) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('chat.send', {
      'scope': scope.apiValue,
      'scopeId': scopeId,
      'body': body,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    });
  }

  void emitRead({required ChatScope scope, required String scopeId}) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('chat.read', {
      'scope': scope.apiValue,
      'scopeId': scopeId,
    });
  }

  void deleteMessage({
    required ChatScope scope,
    required String scopeId,
    required String messageId,
  }) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('chat.delete', {
      'scope': scope.apiValue,
      'scopeId': scopeId,
      'messageId': messageId,
    });
  }

  Future<void> reconnectWithFreshToken() async {
    if (!_started && _joinCounts.isEmpty) return;
    final joined = Map<String, int>.from(_joinCounts);
    await disconnect();
    _started = false;
    _joinCounts.addAll(joined);
    await start();
  }

  Future<void> stop() async {
    _started = false;
    _joinCounts.clear();
    _activeRoomKey = null;
    await disconnect();
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      socket.clearListeners();
      socket.disconnect();
      socket.dispose();
    } catch (e) {
      debugPrint('ChatSocketService: disconnect error $e');
    }
  }

  @override
  void onClose() {
    unawaited(stop());
    unawaited(_messagesController.close());
    unawaited(_readsController.close());
    unawaited(_deletedController.close());
    super.onClose();
  }

  void _applyDeletedInbox(ChatMessageDeletedEvent event) {
    final inbox = event.inboxUpdated;
    if (inbox == null || inbox.lastMessageId.isEmpty) {
      ChatInboxCache.remove(event.scope, event.scopeId);
      return;
    }
    ChatInboxCache.applyLastMessage(inbox);
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
