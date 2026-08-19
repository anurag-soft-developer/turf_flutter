import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';

class TeamLogo extends StatelessWidget {
  const TeamLogo({
    super.key,
    required this.url,
    this.size = 48,
    this.teamId,
  });

  final String url;
  final double size;
  final String? teamId;

  @override
  Widget build(BuildContext context) {
    final child = url.isEmpty ? _placeholder() : _networkImage();

    if (teamId != null && teamId!.isNotEmpty) {
      return GestureDetector(
        onTap: () => Get.toNamed(
          AppConstants.routes.teamProfile,
          arguments: {'teamId': teamId},
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
        Icons.shield_outlined,
        size: size * 0.5,
        color: const Color(AppColors.primaryColor),
      ),
    );
  }

  Widget _networkImage() {
    return ClipOval(
      child: AppNetworkImage(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }
}
