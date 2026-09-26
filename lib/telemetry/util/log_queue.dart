import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

const liveLogName = 'logs.jsonl';
const sendingLogName = 'logs.sending.jsonl';
const maxLiveLines = 1000;

class LogQueue {
  File? _live;
  File? _sending;
  Future<void> _tail = Future<void>.value();
  DateTime? oldestOccurredAt;
  int _lineCount = 0;

  bool get isAtLimit => _lineCount >= maxLiveLines;

  bool isOlderThan(Duration age) {
    final oldest = oldestOccurredAt;
    if (oldest == null) return false;
    return DateTime.now().toUtc().difference(oldest.toUtc()) > age;
  }

  Future<void> init() async {
    final directory = await getApplicationSupportDirectory();
    _live = File('${directory.path}/$liveLogName');
    _sending = File('${directory.path}/$sendingLogName');
    if (!await _live!.exists()) {
      _lineCount = 0;
      oldestOccurredAt = null;
      return;
    }
    final content = await _live!.readAsString();
    final lines = completeLines(content);
    _lineCount = lines.length;
    oldestOccurredAt = oldestFromLines(lines);
    if (content.isNotEmpty && !content.endsWith('\n')) {
      await _rewriteLive(lines);
    }
  }

  Future<void> append(Map<String, dynamic> event) {
    return _synchronized(() async {
      final live = _requireLive();
      final line = '${jsonEncode(event)}\n';
      await live.writeAsString(line, mode: FileMode.append, flush: true);
      _lineCount += 1;
      oldestOccurredAt ??= _occurredAtOf(event);
    });
  }

  /// Events already renamed aside after a failed upload. Empty files are removed.
  Future<List<Map<String, dynamic>>?> readSending() {
    return _synchronized(() async {
      final sending = _requireSending();
      if (!await sending.exists()) return null;
      final events = decodeEvents(await sending.readAsString());
      if (events.isEmpty) {
        await sending.delete();
        return null;
      }
      return events;
    });
  }

  /// Renames the live file so new lines land in a fresh `logs.jsonl`.
  Future<List<Map<String, dynamic>>?> claimLive() {
    return _synchronized(() async {
      final live = _requireLive();
      final sending = _requireSending();
      if (await sending.exists()) return null;
      if (!await live.exists() || _lineCount == 0) return null;
      await live.rename(sending.path);
      _lineCount = 0;
      oldestOccurredAt = null;
      final events = decodeEvents(await sending.readAsString());
      if (events.isEmpty) {
        if (await sending.exists()) await sending.delete();
        return null;
      }
      return events;
    });
  }

  Future<void> discardSending() {
    return _synchronized(() async {
      final sending = _requireSending();
      if (await sending.exists()) await sending.delete();
    });
  }

  Future<void> deleteAll() {
    return _synchronized(() async {
      final live = _requireLive();
      final sending = _requireSending();
      if (await live.exists()) await live.delete();
      if (await sending.exists()) await sending.delete();
      _lineCount = 0;
      oldestOccurredAt = null;
    });
  }

  Future<void> _rewriteLive(List<String> lines) async {
    final live = _requireLive();
    final body = lines.isEmpty ? '' : '${lines.join('\n')}\n';
    await live.writeAsString(body, flush: true);
  }

  File _requireLive() {
    final file = _live;
    if (file == null) {
      throw StateError('Log queue is not started');
    }
    return file;
  }

  File _requireSending() {
    final file = _sending;
    if (file == null) {
      throw StateError('Log queue is not started');
    }
    return file;
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }
}

/// Lines that end with a newline. A trailing partial line is dropped.
List<String> completeLines(String content) {
  if (content.isEmpty) return const [];
  final finished = content.endsWith('\n');
  final parts = content.split('\n');
  if (parts.isNotEmpty && parts.last.isEmpty) {
    parts.removeLast();
  }
  if (!finished && parts.isNotEmpty) {
    parts.removeLast();
  }
  return parts.where((line) => line.trim().isNotEmpty).toList();
}

List<Map<String, dynamic>> decodeEvents(String content) {
  final events = <Map<String, dynamic>>[];
  for (final line in completeLines(content)) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        events.add(decoded);
      } else if (decoded is Map) {
        events.add(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Skip a corrupt line left by a crash.
    }
  }
  return events;
}

DateTime? oldestFromLines(List<String> lines) {
  if (lines.isEmpty) return null;
  try {
    final decoded = jsonDecode(lines.first);
    if (decoded is! Map) return null;
    return _occurredAtOf(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

DateTime? _occurredAtOf(Map<String, dynamic> event) {
  final raw = event['occurredAt'];
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}
