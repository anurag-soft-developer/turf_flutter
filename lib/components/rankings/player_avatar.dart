import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.url,
    this.size = 48,
    this.userId,
  });

  final String url;
  final double size;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final child = url.isEmpty ? _placeholder() : _networkImage();

    if (userId != null && userId!.isNotEmpty) {
      return GestureDetector(
        onTap: () => Get.toNamed(
          AppConstants.routes.teamMemberProfile,
          arguments: {'userId': userId},
        ),
        child: child,
      );
    }
    return child;
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.person_outline,
        size: size * 0.5,
        color: const Color(AppColors.primaryColor),
      ),
    );
  }

  Widget _networkImage() {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }
}
