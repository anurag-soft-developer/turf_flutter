import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/api_constants.dart';
import 'package:flutter_application_1/core/models/media_upload_models.dart';
import 'package:flutter_application_1/core/services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Presigned PUT to DigitalOcean Spaces with upload progress.
class MediaUploadService {
  MediaUploadService._();
  static final MediaUploadService instance = MediaUploadService._();

  final ApiService _api = ApiService();

  static String fileNameFromPath(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  /// Returns our Spaces object key when [publicUrl] uses the `/users/{id}/…` layout.
  /// External URLs (pasted from the web) return null — do not send those to delete.
  static String? inferObjectKeyFromPublicUrl(String publicUrl) {
    try {
      final uri = Uri.parse(publicUrl.trim());
      final path = uri.path.replaceFirst(RegExp(r'^/+'), '');
      if (path.startsWith('users/')) {
        return path;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Maps file extension to a value allowed by the storage service.
  static String mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  Future<PresignedUploadInfo?> requestUploadUrl({
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required MediaUploadPurpose purpose,
    String? idempotencyKey,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.storage.uploadUrl,
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'purpose': purpose.apiValue,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
    );
    if (response == null) return null;
    return PresignedUploadInfo.fromJson(response);
  }

  /// `POST /storage/delete` — keys must live under `users/{currentUserId}/`.
  Future<DeleteObjectsResult?> deleteObjects(List<String> objectKeys) async {
    final unique = objectKeys
        .toSet()
        .where((k) => k.trim().isNotEmpty)
        .toList();
    if (unique.isEmpty) {
      return DeleteObjectsResult(deleted: [], failed: []);
    }

    final response = await _api.delete<Map<String, dynamic>>(
      ApiConstants.storage.delete,
      data: {'objectKeys': unique},
    );
    if (response == null) return null;
    return DeleteObjectsResult.fromJson(response);
  }

  /// Upload bytes to the presigned URL; [onProgress] receives 0.0–1.0.
  Future<void> putPresignedBytes({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
    required void Function(double progress) onProgress,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    await dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(headers: headers),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress(sent / total);
      },
    );
  }

  Future<UploadedMediaRef?> uploadLocalFile({
    required File file,
    required MediaUploadPurpose purpose,
    String? idempotencyKey,
    required void Function(double progress) onProgress,
  }) async {
    final path = file.path;
    final mimeType = mimeTypeForPath(path);
    if (mimeType == 'application/octet-stream') {
      throw const FormatException('Unsupported file type');
    }
    final sizeBytes = await file.length();
    final info = await requestUploadUrl(
      fileName: fileNameFromPath(path),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      purpose: purpose,
      idempotencyKey: idempotencyKey ?? _randomIdempotencyKey(),
    );
    if (info == null) return null;
    final bytes = await file.readAsBytes();
    await putPresignedBytes(
      uploadUrl: info.uploadUrl,
      bytes: bytes,
      headers: info.signedHeaders,
      onProgress: onProgress,
    );
    return UploadedMediaRef(fileUrl: info.fileUrl, objectKey: info.objectKey);
  }

  String _randomIdempotencyKey() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(1 << 32)}';
  }
}

/// Drops URLs that are not ours (no Spaces key), deletes the rest via API, and
/// removes successfully deleted URLs from [pending].
Future<void> flushPendingRemoteImageDeletions(List<String> pending) async {
  pending.removeWhere(
    (u) => MediaUploadService.inferObjectKeyFromPublicUrl(u) == null,
  );
  if (pending.isEmpty) return;

  final keys = pending
      .map(MediaUploadService.inferObjectKeyFromPublicUrl)
      .whereType<String>()
      .toList();

  final result = await MediaUploadService.instance.deleteObjects(keys);

  if (result == null) {
    debugPrint('Deferred image deletion failed: no response');
    return;
  }

  final deletedKeys = result.deleted.toSet();
  pending.removeWhere((url) {
    final k = MediaUploadService.inferObjectKeyFromPublicUrl(url);
    return k != null && deletedKeys.contains(k);
  });

  if (result.failed.isNotEmpty || deletedKeys.length != keys.length) {
    debugPrint(
      'Deferred image deletion incomplete: '
      'deleted=${result.deleted.length}/${keys.length}',
    );
  }
}
