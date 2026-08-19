import 'package:flutter/material.dart';
import 'app_network_image.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../core/models/media_upload_models.dart';
import 'image_input.dart';

/// Circular avatar with a camera badge that opens [ImageInput] pick/upload.
///
/// Use for profile photos, team logos, and similar single-image avatars.
class AvatarImageInput extends StatelessWidget {
  final RxList<String> imageUrls;

  /// Shown under the avatar when non-null and non-empty.
  final String? label;

  /// Used when [imageUrls] is empty (e.g. existing profile avatar).
  final String? fallbackUrl;

  final IconData placeholderIcon;
  final MediaUploadPurpose uploadPurpose;
  final void Function(List<String> urls)? onChange;
  final bool deleteRemoteOnRemove;
  final void Function(String url)? onDeferredRemoteRemoval;
  final bool allowPasteUrl;
  final double radius;
  final Color backgroundColor;
  final Color placeholderColor;
  final Color cameraBorderColor;

  const AvatarImageInput({
    super.key,
    required this.imageUrls,
    this.label,
    this.fallbackUrl,
    this.placeholderIcon = Icons.person,
    this.uploadPurpose = MediaUploadPurpose.avatar,
    this.onChange,
    this.deleteRemoteOnRemove = true,
    this.onDeferredRemoteRemoval,
    this.allowPasteUrl = false,
    this.radius = 50,
    this.backgroundColor = Colors.white,
    this.placeholderColor = const Color(AppColors.primaryColor),
    this.cameraBorderColor = const Color(AppColors.primaryColor),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Obx(() {
                final fromList =
                    imageUrls.isNotEmpty ? imageUrls.first : null;
                final fallback = fallbackUrl?.trim();
                final url = fromList ??
                    (fallback != null && fallback.isNotEmpty ? fallback : null);
                return CircleAvatar(
                  radius: radius,
                  backgroundColor: backgroundColor,
                  backgroundImage: url != null ? AppNetworkImage.provider(url) : null,
                  child: url == null
                      ? Icon(
                          placeholderIcon,
                          size: radius,
                          color: placeholderColor,
                        )
                      : null,
                );
              }),
              Positioned(
                bottom: 0,
                right: 0,
                child: ImageInput(
                  title: label ?? 'Avatar',
                  imageUrls: imageUrls,
                  maxImages: 1,
                  uploadPurpose: uploadPurpose,
                  allowPasteUrl: allowPasteUrl,
                  deleteRemoteOnRemove: deleteRemoteOnRemove,
                  onDeferredRemoteRemoval: onDeferredRemoteRemoval,
                  onChange: onChange,
                  buttonChild: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cameraBorderColor,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt,
                      color: cameraBorderColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (label != null && label!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              label!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.textSecondaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
