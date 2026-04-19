import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';

class PlayerHeroSection extends StatelessWidget {
  const PlayerHeroSection({super.key, required this.helper});

  /// Preview length beyond which bio is truncated and tap opens full text.
  static const int _bioPreviewMaxChars = 60;

  final UserFieldInstance helper;

  static void _showFullBio(BuildContext context, String bio) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Color(AppColors.surfaceColor),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.2,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).viewPadding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = helper.getModel();
    final title = helper.getDisplayName();

    return Container(
      constraints: BoxConstraints(
        minHeight: 280,
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(AppColors.primaryColor),
            const Color(AppColors.primaryColor).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30), // Space for app bar
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage:
                    helper.getAvatar() != null && helper.getAvatar()!.isNotEmpty
                    ? NetworkImage(helper.getAvatar()!)
                    : null,
                child: helper.getAvatar() == null || helper.getAvatar()!.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),

              const SizedBox(height: 8),

              // Name
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              // Email
              // if (helper.getEmail() != null) ...[
              //   const SizedBox(height: 2),
              //   Text(
              //     helper.getEmail()!,
              //     textAlign: TextAlign.center,
              //     style: TextStyle(
              //       fontSize: 14,
              //       color: Colors.white.withValues(alpha: 0.9),
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ],

              // Bio preview
              if (model?.bio != null && model!.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final bio = model.bio!;
                    final isLong = bio.length > _bioPreviewMaxChars;
                    final preview = isLong
                        ? '${bio.substring(0, _bioPreviewMaxChars)}...'
                        : bio;

                    final textStyle = TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.3,
                    );

                    final textWidget = Text(
                      preview,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    );

                    if (!isLong) return textWidget;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showFullBio(context, bio),
                      child: textWidget,
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
