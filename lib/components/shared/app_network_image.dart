import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/cache/app_image_cache.dart';

export '../../core/cache/app_image_cache.dart';

/// Drop-in for [Image.network] that stores files on disk.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.imageUrl, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.placeholder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Widget? placeholder;

  static ImageProvider provider(String url) => CachedNetworkImageProvider(
        url,
        cacheManager: AppImageCache.instance,
      );

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: AppImageCache.instance,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: placeholder == null ? null : (_, __) => placeholder!,
      errorWidget: (context, url, error) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error, null);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
