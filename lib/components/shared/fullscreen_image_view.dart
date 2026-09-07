import 'package:flutter/material.dart';

import 'app_network_image.dart';

void showFullscreenImage(BuildContext context, String imageUrl) {
  final url = imageUrl.trim();
  if (url.isEmpty) return;

  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (context, _, __) => _FullscreenImagePage(imageUrl: url),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}

class _FullscreenImagePage extends StatelessWidget {
  const _FullscreenImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: AppNetworkImage(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
