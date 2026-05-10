// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;

// import '../core/config/env_config.dart';
// import '../core/services/auth_storage_service.dart';
// import 'model/scoring_models.dart';

// /// Read-only socket bridge to realtime-turf-services for live scoring.
// ///
// /// Writes (append ball / append event) flow over HTTP via [ScoringApiService].
// /// This client only joins/leaves session rooms and listens for `scoring.update`
// /// broadcasts that turf-services dispatched after persisting an event.
// class ScoringSocketService {
//   ScoringSocketService({AuthStorageService? authStorageService})
//     : _authStorageService = authStorageService ?? AuthStorageService();

//   final AuthStorageService _authStorageService;
//   io.Socket? _socket;
//   final StreamController<ScoringUpdatePayload> _updatesController =
//       StreamController<ScoringUpdatePayload>.broadcast();

//   Stream<ScoringUpdatePayload> get updatesStream => _updatesController.stream;
//   bool get isConnected => _socket?.connected == true;

//   Future<void> connect() async {
//     if (_socket?.connected == true) return;

//     final token = await _authStorageService.getAccessToken();
//     if (token == null || token.isEmpty) {
//       throw Exception('Missing access token for scoring socket.');
//     }

//     final wsUrl = EnvConfig.realtimeWsUrl;
//     if (wsUrl.isEmpty) {
//       throw Exception('Missing REALTIME_WS_URL configuration.');
//     }

//     _socket?.dispose();
//     _socket = io.io(
//       '$wsUrl/scoring',
//       io.OptionBuilder()
//           .setTransports(['websocket'])
//           .setPath(EnvConfig.realtimeSocketPath)
//           .disableAutoConnect()
//           .enableReconnection()
//           .setAuth({'token': token})
//           .build(),
//     );

//     _bindCoreListeners(_socket!);
//     _socket!.connect();
//   }

//   Future<void> disconnect() async {
//     _socket?.disconnect();
//     _socket?.dispose();
//     _socket = null;
//   }

//   Future<String> joinSession(String sessionId) async {
//     final response = await _emitWithAck('scoring.join', {
//       'sessionId': sessionId,
//     });
//     return response['room']?.toString() ?? '';
//   }

//   Future<String> leaveSession(String sessionId) async {
//     final response = await _emitWithAck('scoring.leave', {
//       'sessionId': sessionId,
//     });
//     return response['room']?.toString() ?? '';
//   }

//   Future<Map<String, dynamic>> _emitWithAck(
//     String event,
//     Map<String, dynamic> payload,
//   ) async {
//     final socket = _socket;
//     if (socket == null || socket.connected != true) {
//       throw Exception('Scoring socket is not connected.');
//     }

//     final completer = Completer<Map<String, dynamic>>();
//     socket.emitWithAck(
//       event,
//       payload,
//       ack: (dynamic raw) {
//         if (raw is Map<String, dynamic>) {
//           completer.complete(raw);
//           return;
//         }
//         if (raw is Map) {
//           completer.complete(raw.cast<String, dynamic>());
//           return;
//         }
//         completer.completeError(
//           Exception('Unexpected ack payload for $event: $raw'),
//         );
//       },
//     );

//     return completer.future.timeout(
//       const Duration(seconds: 8),
//       onTimeout: () => throw TimeoutException('$event ack timed out'),
//     );
//   }

//   void _bindCoreListeners(io.Socket socket) {
//     socket.onConnect((_) {
//       debugPrint('[ScoringSocket] connected id=${socket.id}');
//     });

//     socket.onDisconnect((reason) {
//       debugPrint('[ScoringSocket] disconnected reason=$reason');
//     });

//     socket.onConnectError((error) {
//       debugPrint('[ScoringSocket] connect_error=$error');
//     });

//     socket.onError((error) {
//       debugPrint('[ScoringSocket] error=$error');
//     });

//     socket.on('scoring.update', (dynamic raw) {
//       try {
//         final json = raw is Map<String, dynamic>
//             ? raw
//             : (raw as Map).cast<String, dynamic>();
//         _updatesController.add(ScoringUpdatePayload.fromJson(json));
//       } catch (error) {
//         debugPrint('[ScoringSocket] invalid scoring.update payload: $error');
//       }
//     });
//   }

//   void dispose() {
//     disconnect();
//     _updatesController.close();
//   }
// }
