import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses editor output (usually JPEG) to a WebP file for upload.
///
/// Caps the long side and quality so post media stays small. Falls back to
/// JPEG if WebP encoding is unavailable on the device.
Future<XFile> compressEditorBytesToWebp(Uint8List bytes) async {
  const maxBytes = 400 * 1024;
  var maxSide = 1440;
  var quality = 82;
  var format = CompressFormat.webp;
  var ext = 'webp';

  Future<Uint8List?> encode() async {
    try {
      final encoded = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxSide,
        minHeight: maxSide,
        quality: quality,
        format: format,
      );
      if (encoded.isEmpty) return null;
      return encoded;
    } catch (e) {
      debugPrint('Image compress failed ($format q$quality): $e');
      return null;
    }
  }

  var out = await encode();
  if (out == null) {
    format = CompressFormat.jpeg;
    ext = 'jpg';
    quality = 82;
    out = await encode();
  }

  if (out == null) {
    throw StateError('Image compression produced empty output');
  }

  var compressed = out;
  while (compressed.lengthInBytes > maxBytes &&
      (quality > 50 || maxSide > 1080)) {
    if (quality > 50) {
      quality -= 8;
    } else {
      maxSide = 1080;
    }
    final next = await encode();
    if (next == null) break;
    compressed = next;
  }

  final path =
      '${Directory.systemTemp.path}/post_${DateTime.now().microsecondsSinceEpoch}.$ext';
  final file = File(path);
  await file.writeAsBytes(compressed, flush: true);
  return XFile(
    file.path,
    mimeType: ext == 'webp' ? 'image/webp' : 'image/jpeg',
  );
}
