import 'dart:async';

import '../../core/config/api_constants.dart';
import '../../core/services/api_service.dart';
import 'engagement_entity.dart';

class EngagementService {
  static final EngagementService _instance = EngagementService._internal();
  factory EngagementService() => _instance;
  EngagementService._internal();

  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _queue = [];
  final Set<String> _sentKeys = {};
  Timer? _flushTimer;

  static const _maxBatch = 50;
  static const _debounce = Duration(seconds: 2);

  void trackImpression({
    required EngagementEntityType entityType,
    required String entityId,
  }) {
    _enqueue(
      entityType: entityType,
      entityId: entityId,
      kind: EngagementEventKind.impression,
    );
  }

  void trackView({
    required EngagementEntityType entityType,
    required String entityId,
  }) {
    _enqueue(
      entityType: entityType,
      entityId: entityId,
      kind: EngagementEventKind.view,
    );
  }

  void _enqueue({
    required EngagementEntityType entityType,
    required String entityId,
    required EngagementEventKind kind,
    int? watchMs,
  }) {
    if (entityId.isEmpty) return;
    final key = '${entityType.apiValue}:$entityId:${kind.apiValue}';
    if (!_sentKeys.add(key)) return;

    final event = <String, dynamic>{
      'entityType': entityType.apiValue,
      'entityId': entityId,
      'kind': kind.apiValue,
      if (watchMs != null) 'watchMs': watchMs,
    };
    _queue.add(event);
    _scheduleFlush();
    if (_queue.length >= _maxBatch) {
      unawaited(flush());
    }
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_debounce, () {
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_queue.isEmpty) return;

    final batch = _queue.take(_maxBatch).toList();
    _queue.removeRange(0, batch.length);

    final ok = await _apiService.postNoContent(
      ApiConstants.engagement.batch,
      data: {'events': batch},
    );
    if (!ok) {
      _queue.insertAll(0, batch);
    } else if (_queue.isNotEmpty) {
      _scheduleFlush();
    }
  }

  Future<bool> like({
    required EngagementEntityType entityType,
    required String entityId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.engagement.likes,
      data: {
        'entityType': entityType.apiValue,
        'entityId': entityId,
      },
    );
    return response != null && response['liked'] == true;
  }

  Future<bool> unlike({
    required EngagementEntityType entityType,
    required String entityId,
  }) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.engagement.likes,
      data: {
        'entityType': entityType.apiValue,
        'entityId': entityId,
      },
    );
    return response != null && response['liked'] == false;
  }
}
