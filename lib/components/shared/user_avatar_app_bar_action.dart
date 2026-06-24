import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';

class UserAvatarAppBarAction extends StatelessWidget {
  const UserAvatarAppBarAction({
    super.key,
    this.size = 34,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });

  final double size;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthStateController>();

    return Obx(() {
      final avatar = authController.user?.avatar;

      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed(AppConstants.routes.appMenu),
              customBorder: const CircleBorder(),
              child: Container(
                width: size + borderWidth * 2,
                height: size + borderWidth * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: CircleAvatar(
                  radius: size / 2,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Icon(
                          Icons.person,
                          color: const Color(AppColors.primaryColor),
                          size: size * 0.55,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
