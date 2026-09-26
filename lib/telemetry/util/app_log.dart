import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_application_1/core/config/api_constants.dart';
import 'package:flutter_application_1/core/services/api_service.dart';
import 'package:flutter_application_1/core/services/auth_storage_service.dart';
import 'package:flutter_application_1/telemetry/util/log_queue.dart';
import 'package:flutter_application_1/telemetry/log_service.dart';
import 'package:flutter_application_1/telemetry/util/log_util.dart';
import 'package:flutter_application_1/telemetry/util/screen_tracker_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _stackLimit = 2048;
const _messageLimit = 1000;
const _payloadLimit = 4096;
const _maxDurationMs = 7 * 24 * 60 * 60 * 1000;
const _flushAge = Duration(hours: 1);
const _telemetryLog = '\x1B[36m[telemetry]';

void _telemetryDebug(String message) {
  debugPrint('$_telemetryLog $message\x1B[0m');
}

class _PendingError {
  _PendingError(this.error, this.stack);

  final Object error;
  final StackTrace? stack;
}

/// Process-wide logger. Safe to call before GetX is ready.
class AppLog {
  AppLog._();

  static final AppLog instance = AppLog._();

  static const consentKey = 'analytics_consent';
  static const _installIdKey = 'telemetry_install_id';
  static const _appId = 'turf_flutter';

  final LogQueue _queue = LogQueue();
  final ScreenTracker _screens = ScreenTracker();
  final AuthStorageService _authStorage = AuthStorageService();
  final List<_PendingError> _pendingErrors = [];

  Future<void>? _starting;
  bool _started = false;
  bool _flushing = false;
  bool _consent = false;
  int _sendingFailures = 0;
  bool consentAnswered = false;

  String _installId = '';
  String _sessionId = '';
  String _appVersion = 'unknown';
  String _platform = '';
  String _osVersion = '';
  String? _resumeRoute;
  String? _pendingRoute;
  String? _lastErrorKey;
  DateTime? _lastErrorAt;

  bool get shouldPromptConsent => _started && !consentAnswered;

  Future<void> start() {
    return _starting ??= _start();
  }

  void recordError(Object error, StackTrace? stack) {
    final key = '${error.runtimeType}:${error.toString()}';
    final now = DateTime.now();
    if (_lastErrorKey == key &&
        _lastErrorAt != null &&
        now.difference(_lastErrorAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastErrorKey = key;
    _lastErrorAt = now;
    if (!_started) {
      if (_pendingErrors.length < 50) {
        _pendingErrors.add(_PendingError(error, stack));
      }
      return;
    }
    unawaited(_writeError(error, stack));
  }

  void onRoute(String? route) {
    if (route == null || route.isEmpty) return;
    if (!_started) {
      _pendingRoute = route;
      return;
    }
    _advanceRoute(route, DateTime.now().toUtc());
  }

  void onPause() {
    if (!_started) return;
    final closed = _screens.take();
    if (closed == null) return;
    _resumeRoute = closed.route;
    unawaited(
      _writeScreen(
        route: closed.route,
        enteredAt: closed.enteredAt,
        closedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void onResume() {
    if (!_started) return;
    final route = _resumeRoute;
    if (route != null && route.isNotEmpty) {
      _screens.open(route, DateTime.now().toUtc());
    }
    unawaited(flush(includeLive: true));
  }

  Future<void> setConsent(bool enabled) async {
    await start();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(consentKey, enabled);
    _consent = enabled;
    consentAnswered = true;
    if (_screens.route != null) {
      _screens.open(_screens.route!, DateTime.now().toUtc());
    }
    if (!enabled) {
      _sendingFailures = 0;
      if (_started) await _queue.deleteAll();
      return;
    }
    await flush(includeLive: true);
  }

  Future<void> flush({required bool includeLive}) async {
    if (!_started || !_consent || _flushing) {
      _telemetryDebug(
        'flush skipped '
        'started=$_started consent=$_consent flushing=$_flushing',
      );
      return;
    }
    _flushing = true;
    try {
      final pending = await _queue.readSending();
      if (pending != null) {
        final proceed = await _finishUpload(pending);
        if (!proceed) return;
      }
      if (!includeLive && !_queue.isOlderThan(_flushAge)) return;
      if (!_consent) return;
      final claimed = await _queue.claimLive();
      if (claimed == null || !_consent) {
        _telemetryDebug('nothing to upload');
        return;
      }
      _telemetryDebug('uploading ${claimed.length} events');
      await _finishUpload(claimed);
    } catch (_) {
      // Keep the sending file for the next resume or hour check.
    } finally {
      _flushing = false;
    }
  }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    consentAnswered = prefs.containsKey(consentKey);
    _consent = prefs.getBool(consentKey) ?? false;

    final storedInstallId = prefs.getString(_installIdKey);
    if (storedInstallId == null || storedInstallId.isEmpty) {
      _installId = const Uuid().v4();
      await prefs.setString(_installIdKey, _installId);
    } else {
      _installId = storedInstallId;
    }
    _sessionId = const Uuid().v4();
    _platform = Platform.operatingSystem;
    _osVersion = clipText(Platform.operatingSystemVersion, 120);
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'unknown';
    }

    await _queue.init();
    _started = true;

    final pendingRoute = _pendingRoute;
    _pendingRoute = null;
    if (pendingRoute != null) {
      _advanceRoute(pendingRoute, DateTime.now().toUtc());
    }

    final pendingErrors = List<_PendingError>.from(_pendingErrors);
    _pendingErrors.clear();
    for (final pending in pendingErrors) {
      await _writeError(pending.error, pending.stack);
    }
  }

  void _advanceRoute(String route, DateTime at) {
    final current = _screens.route;
    if (current == route) return;
    final closed = _screens.take();
    _screens.open(route, at);
    if (closed == null) return;
    unawaited(
      _writeScreen(
        route: closed.route,
        enteredAt: closed.enteredAt,
        closedAt: at,
      ),
    );
  }

  Future<void> _writeScreen({
    required String route,
    required DateTime enteredAt,
    required DateTime closedAt,
  }) async {
    if (!_consent) return;
    var durationMs = closedAt.difference(enteredAt).inMilliseconds;
    if (durationMs < 0) durationMs = 0;
    if (durationMs > _maxDurationMs) durationMs = _maxDurationMs;
    await _append(
      kind: 'screen',
      name: clipText(route, 200),
      level: 'info',
      occurredAt: enteredAt,
      durationMs: durationMs,
      payload: const {},
    );
  }

  Future<void> _writeError(Object error, StackTrace? stack) async {
    final message = clipText(
      redactSensitiveText(error.toString()),
      _messageLimit,
    );
    final stackText = stack == null
        ? ''
        : clipText(redactSensitiveText(stack.toString()), _stackLimit);
    await _append(
      kind: 'error',
      name: clipText(error.runtimeType.toString(), 200),
      level: 'error',
      occurredAt: DateTime.now().toUtc(),
      payload: {
        'message': message,
        if (stackText.isNotEmpty) 'stack': stackText,
      },
    );
  }

  Future<void> _append({
    required String kind,
    required String name,
    required String level,
    required DateTime occurredAt,
    int? durationMs,
    required Map<String, dynamic> payload,
  }) async {
    if (!_started) {
      _telemetryDebug('write skipped, logger not started');
      return;
    }
    if (kind == 'screen' && !_consent) {
      _telemetryDebug('screen write skipped, consent off');
      return;
    }
    final event = <String, dynamic>{
      'appId': _appId,
      'platform': _platform,
      'appVersion': _appVersion,
      'installId': _installId,
      'sessionId': _sessionId,
      'kind': kind,
      'name': name,
      'level': level,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      if (durationMs != null) 'durationMs': durationMs,
      'count': 1,
      'clientEventId': const Uuid().v4(),
      'payload': _boundedPayload(payload),
    };
    try {
      await _queue.append(event);
      _telemetryDebug(
        'wrote $kind name=$name '
        'atLimit=${_queue.isAtLimit} consent=$_consent',
      );
    } catch (error) {
      _telemetryDebug('write failed: $error');
      return;
    }
    if (_consent && (_queue.isOlderThan(_flushAge) || _queue.isAtLimit)) {
      await flush(includeLive: true);
    }
  }

  Map<String, dynamic> _boundedPayload(Map<String, dynamic> payload) {
    var next = <String, dynamic>{'osVersion': _osVersion, ...payload};
    if (utf8.encode(jsonEncode(next)).length <= _payloadLimit) return next;

    final stack = next['stack'];
    if (stack is String && stack.length > 512) {
      next = {...next, 'stack': stack.substring(0, 512)};
    }
    final message = next['message'];
    if (message is String &&
        utf8.encode(jsonEncode(next)).length > _payloadLimit &&
        message.length > 256) {
      next = {...next, 'message': message.substring(0, 256)};
    }
    return next;
  }

  /// Deletes the sending file on success, on a client rejection, or after a
  /// second retryable failure. Returns whether the newer live file may upload.
  Future<bool> _finishUpload(List<Map<String, dynamic>> events) async {
    final outcome = await _upload(events);
    if (!_consent) return false;
    final giveUp =
        outcome == _UploadOutcome.drop ||
        (outcome == _UploadOutcome.retry && _sendingFailures >= 1);
    if (outcome == _UploadOutcome.sent || giveUp) {
      _sendingFailures = 0;
      await _queue.discardSending();
      return true;
    }
    _sendingFailures += 1;
    return false;
  }

  Future<_UploadOutcome> _upload(List<Map<String, dynamic>> events) async {
    if (!_consent) return _UploadOutcome.retry;
    final token = await _authStorage.getAccessToken();
    var status = await uploadClientLogs(
      baseUrl: ApiConstants.baseUrl,
      path: ApiConstants.telemetry.batch,
      accessToken: token,
      events: events,
    );
    if (status == 401 && token != null && token.isNotEmpty) {
      final refreshed = await ApiService().refreshAccessToken();
      if (!refreshed || !_consent) return _UploadOutcome.retry;
      final nextToken = await _authStorage.getAccessToken();
      status = await uploadClientLogs(
        baseUrl: ApiConstants.baseUrl,
        path: ApiConstants.telemetry.batch,
        accessToken: nextToken,
        events: events,
      );
    }
    _telemetryDebug('upload status=$status events=${events.length}');
    if (status == 0) return _UploadOutcome.sent;
    if (status == 401) return _UploadOutcome.retry;
    if (status >= 400 && status < 500) return _UploadOutcome.drop;
    return _UploadOutcome.retry;
  }
}

enum _UploadOutcome { sent, retry, drop }
