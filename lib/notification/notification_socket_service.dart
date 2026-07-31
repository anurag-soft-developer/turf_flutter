import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/config/env_config.dart';
import 'package:flutter_application_1/core/services/auth_storage_service.dart';
import 'package:flutter_application_1/notification/notification_inbox_cache.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Live inbox updates via Socket.io namespace `/notifications`.
class NotificationSocketService extends GetxService {
  static NotificationSocketService get instance => Get.find();

  final AuthStorageService _authStorage = AuthStorageService();

  io.Socket? _socket;
  bool _started = false;

  Future<void> start() async {
    if (_started && _socket != null) return;

    final baseUrl = EnvConfig.realtimeWsUrl.trim();
    if (baseUrl.isEmpty) {
      debugPrint(
        'NotificationSocketService: REALTIME_WS_URL empty; live inbox disabled',
      );
      return;
    }

    final token = await _authStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('NotificationSocketService: no access token; skip connect');
      return;
    }

    await disconnect();
    _started = true;

    final url = baseUrl.endsWith('/')
        ? '${baseUrl.substring(0, baseUrl.length - 1)}/notifications'
        : '$baseUrl/notifications';

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
      debugPrint('NotificationSocketService: connected');
    });

    socket.onDisconnect((_) {
      debugPrint('NotificationSocketService: disconnected');
    });

    socket.onConnectError((error) {
      debugPrint('NotificationSocketService: connect error $error');
    });

    socket.on('notification.push', (dynamic raw) {
      try {
        final map = _asStringKeyedMap(raw);
        if (map == null) return;
        final notification = NotificationInboxCache.fromPushPayload(map);
        if (notification.id.isEmpty) return;
        NotificationInboxCache.prepend(notification);
      } catch (e, st) {
        debugPrint('notification.push handle failed: $e\n$st');
      }
    });

    _socket = socket;
    socket.connect();
  }

  Future<void> reconnectWithFreshToken() async {
    if (!_started) return;
    await disconnect();
    _started = false;
    await start();
  }

  Future<void> stop() async {
    _started = false;
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
      debugPrint('NotificationSocketService: disconnect error $e');
    }
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
