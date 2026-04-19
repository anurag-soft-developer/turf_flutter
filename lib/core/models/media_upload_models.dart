/// Matches backend [MediaUploadPurpose] (Nest `media-upload.dto`).
enum MediaUploadPurpose {
  postMedia('postMedia'),
  avatar('avatar'),
  turfMedia('turfMedia'),
  teamMedia('teamMedia');

  const MediaUploadPurpose(this.apiValue);
  final String apiValue;
}

/// Result of uploading a local file via presigned PUT.
class UploadedMediaRef {
  final String fileUrl;
  final String objectKey;

  UploadedMediaRef({required this.fileUrl, required this.objectKey});
}

/// Response from `POST /storage/delete`.
class DeleteObjectsResult {
  final List<String> deleted;
  final List<DeleteObjectFailure> failed;

  DeleteObjectsResult({
    required this.deleted,
    required this.failed,
  });

  factory DeleteObjectsResult.fromJson(Map<String, dynamic> json) {
    final deletedRaw = json['deleted'];
    final failedRaw = json['failed'];

    final deleted = <String>[
      if (deletedRaw is List) ...deletedRaw.whereType<String>(),
    ];

    final failed = <DeleteObjectFailure>[];
    if (failedRaw is List) {
      for (final e in failedRaw) {
        if (e is Map<String, dynamic>) {
          failed.add(DeleteObjectFailure.fromJson(e));
        }
      }
    }

    return DeleteObjectsResult(deleted: deleted, failed: failed);
  }
}

class DeleteObjectFailure {
  final String objectKey;
  final String? code;
  final String? message;

  DeleteObjectFailure({
    required this.objectKey,
    this.code,
    this.message,
  });

  factory DeleteObjectFailure.fromJson(Map<String, dynamic> json) {
    return DeleteObjectFailure(
      objectKey: json['objectKey'] as String? ?? '',
      code: json['code'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// Response from `POST /storage/upload-url`.
class PresignedUploadInfo {
  final String uploadUrl;
  final String fileUrl;
  final String objectKey;
  final String expiresAt;
  final Map<String, String> signedHeaders;

  PresignedUploadInfo({
    required this.uploadUrl,
    required this.fileUrl,
    required this.objectKey,
    required this.expiresAt,
    required this.signedHeaders,
  });

  factory PresignedUploadInfo.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    final Map<String, String> headers = {};
    if (headersRaw is Map) {
      headersRaw.forEach((key, value) {
        if (key != null && value != null) {
          headers[key.toString()] = value.toString();
        }
      });
    }
    return PresignedUploadInfo(
      uploadUrl: json['uploadUrl'] as String,
      fileUrl: json['fileUrl'] as String,
      objectKey: json['objectKey'] as String,
      expiresAt: json['expiresAt'] as String,
      signedHeaders: headers,
    );
  }
}
