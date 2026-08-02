import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/config/env_config.dart';
import 'package:flutter_application_1/core/services/auth_storage_service.dart';
import 'package:flutter_application_1/scoring/shared/scoring_shared_models.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Live scoring updates via Socket.io namespace `/scoring`.
class ScoringSocketService extends GetxService {
  static ScoringSocketService get instance => Get.find();

  final AuthStorageService _authStorage = AuthStorageService();

  io.Socket? _socket;
  bool _started = false;
  final Map<String, int> _joinCounts = <String, int>{};

  final StreamController<ScoringUpdatePayload> _updatesController =
      StreamController<ScoringUpdatePayload>.broadcast();

  Stream<ScoringUpdatePayload> get updates => _updatesController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> start() async {
    if (_started && _socket != null) return;

    final baseUrl = EnvConfig.realtimeWsUrl.trim();
    if (baseUrl.isEmpty) {
      debugPrint(
        'ScoringSocketService: REALTIME_WS_URL empty; live scoring disabled',
      );
      return;
    }

    final token = await _authStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('ScoringSocketService: no access token; skip connect');
      return;
    }

    await disconnect();
    _started = true;

    final url = baseUrl.endsWith('/')
        ? '${baseUrl.substring(0, baseUrl.length - 1)}/scoring'
        : '$baseUrl/scoring';

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
      debugPrint('ScoringSocketService: connected');
      for (final entry in _joinCounts.entries) {
        if (entry.value <= 0) continue;
        socket.emit('scoring.join', {'teamMatchId': entry.key});
      }
    });

    socket.onDisconnect((_) {
      debugPrint('ScoringSocketService: disconnected');
    });

    socket.onConnectError((error) {
      debugPrint('ScoringSocketService: connect error $error');
    });

    socket.on('scoring.update', (dynamic raw) {
      try {
        final map = _asStringKeyedMap(raw);
        if (map == null) return;
        final payload = ScoringUpdatePayload.fromJson(map);
        if (payload.teamMatchId.isEmpty) return;
        _updatesController.add(payload);
      } catch (e, st) {
        debugPrint('scoring.update handle failed: $e\n$st');
      }
    });

    _socket = socket;
    socket.connect();
  }

  Future<void> joinMatch(String teamMatchId) async {
    final id = teamMatchId.trim();
    if (id.isEmpty) return;
    await start();
    final next = (_joinCounts[id] ?? 0) + 1;
    _joinCounts[id] = next;
    if (next != 1) return;
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('scoring.join', {'teamMatchId': id});
  }

  Future<void> leaveMatch(String teamMatchId) async {
    final id = teamMatchId.trim();
    if (id.isEmpty) return;
    final current = _joinCounts[id] ?? 0;
    if (current <= 0) return;
    final next = current - 1;
    if (next > 0) {
      _joinCounts[id] = next;
      return;
    }
    _joinCounts.remove(id);
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('scoring.leave', {'teamMatchId': id});
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
      debugPrint('ScoringSocketService: disconnect error $e');
    }
  }

  @override
  void onClose() {
    unawaited(stop());
    unawaited(_updatesController.close());
    super.onClose();
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
