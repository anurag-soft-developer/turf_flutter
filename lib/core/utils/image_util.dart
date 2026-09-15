import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses editor output (usually JPEG) to a WebP file for upload.
///
/// Caps the long side and quality so uploads stay small. Falls back to
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
    }
    return null;
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
      '${Directory.systemTemp.path}/edited_${DateTime.now().microsecondsSinceEpoch}.$ext';
  final file = File(path);
  await file.writeAsBytes(compressed, flush: true);
  return XFile(
    file.path,
    mimeType: ext == 'webp' ? 'image/webp' : 'image/jpeg',
  );
}

/// Local pixel size for feed aspect ratio. Omits dims on failure.
Future<(int, int)?> readPixelSize(XFile file) {
  final completer = Completer<(int, int)?>();
  final stream =
      FileImage(File(file.path)).resolve(const ImageConfiguration());
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      final width = info.image.width;
      final height = info.image.height;
      if (width <= 0 || height <= 0) {
        completer.complete(null);
        return;
      }
      completer.complete((width, height));
    },
    onError: (_, __) {
      stream.removeListener(listener);
      completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

/// Aspect ratio from stored pixel dims, or null if missing/invalid.
double? storedRatio(int? width, int? height) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }
  return width / height;
}
