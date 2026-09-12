import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';

import 'seen_avatars_controller.dart';

class SeenAvatars extends StatelessWidget {
  const SeenAvatars({
    super.key,
    required this.userIds,
    required this.resolveUser,
    this.onTap,
  });

  final List<String> userIds;
  final Future<User?> Function(String id) resolveUser;
  final VoidCallback? onTap;

  static const _maxVisible = 3;
  static const _size = 18.0;
  static const _overlap = 8.0;

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) return const SizedBox.shrink();

    return GetBuilder<SeenAvatarsController>(
      init: SeenAvatarsController(
        userIds: userIds,
        resolveUser: resolveUser,
      ),
      global: false,
      builder: (controller) {
        return Obx(() {
          final extra = userIds.length - _maxVisible;
          final visible = controller.users.take(_maxVisible).toList();
          final slotCount = visible.length + (extra > 0 ? 1 : 0);
          final width = _size + (slotCount - 1) * (_size - _overlap);

          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: width,
                height: _size,
                child: Stack(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      Positioned(
                        left: i * (_size - _overlap),
                        child: _SeenAvatarDot(user: visible[i]),
                      ),
                    if (extra > 0)
                      Positioned(
                        left: visible.length * (_size - _overlap),
                        child: _SeenCountDot(count: extra),
                      ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _SeenAvatarDot extends StatelessWidget {
  const _SeenAvatarDot({required this.user});

  final SeenAvatarUser user;

  @override
  Widget build(BuildContext context) {
    final url = user.imageUrl;
    final initial = user.name.trim().isEmpty
        ? null
        : user.name.trim()[0].toUpperCase();

    return Container(
      width: SeenAvatars._size,
      height: SeenAvatars._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(AppColors.backgroundColor),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: SeenAvatars._size / 2,
        backgroundColor: const Color(AppColors.dividerColor),
        backgroundImage: url != null && url.isNotEmpty
            ? AppNetworkImage.provider(url)
            : null,
        child: url == null || url.isEmpty
            ? Text(
                initial ?? '',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textSecondaryColor),
                ),
              )
            : null,
      ),
    );
  }
}

class _SeenCountDot extends StatelessWidget {
  const _SeenCountDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SeenAvatars._size,
      height: SeenAvatars._size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(AppColors.primaryColor),
        border: Border.all(
          color: const Color(AppColors.backgroundColor),
          width: 1.5,
        ),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
