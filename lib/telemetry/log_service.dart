import 'dart:isolate';

import 'package:dio/dio.dart';

const telemetryBatchLimit = 200;

/// Posts already-read events. Returns 0 on success, 401 when the token must be
/// refreshed, and another status when the batch should stay on disk.
Future<int> uploadClientLogs({
  required String baseUrl,
  required String path,
  required String? accessToken,
  required List<Map<String, dynamic>> events,
}) {
  return Isolate.run(
    () => _postClientLogs(
      baseUrl: baseUrl,
      path: path,
      accessToken: accessToken,
      events: events,
    ),
  );
}

Future<int> _postClientLogs({
  required String baseUrl,
  required String path,
  required String? accessToken,
  required List<Map<String, dynamic>> events,
}) async {
  if (events.isEmpty) return 0;
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (accessToken != null && accessToken.isNotEmpty) {
    headers['Authorization'] = 'Bearer $accessToken';
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      headers: headers,
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  try {
    for (var start = 0; start < events.length; start += telemetryBatchLimit) {
      final end = start + telemetryBatchLimit < events.length
          ? start + telemetryBatchLimit
          : events.length;
      final response = await dio.post<void>(
        path,
        data: {'events': events.sublist(start, end)},
      );
      final status = response.statusCode ?? 0;
      if (status == 401) return 401;
      if (status < 200 || status >= 300) return status == 0 ? 500 : status;
    }
    return 0;
  } on DioException {
    return 500;
  } finally {
    dio.close(force: true);
  }
}
