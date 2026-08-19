import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_network_image.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../follow/follow_button.dart';
import '../follow/follow_stat_button.dart';

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
        minHeight: 240,
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
              // Avatar beside name + follow stats to keep the hero compact.
              Row(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage:
                        helper.getAvatar() != null &&
                            helper.getAvatar()!.isNotEmpty
                        ? AppNetworkImage.provider(helper.getAvatar()!)
                        : null,
                    child:
                        helper.getAvatar() == null ||
                            helper.getAvatar()!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Follower / following stats
                        Builder(
                          builder: (context) {
                            final userId = helper.getId();
                            final canNavigate =
                                userId != null && userId.isNotEmpty;

                            void openList(String path) {
                              if (!canNavigate) return;
                              Get.toNamed(
                                Uri(
                                  path: path,
                                  queryParameters: {'name': title},
                                ).toString(),
                              );
                            }

                            return Row(
                              children: [
                                FollowStatButton(
                                  count: model?.followerCount ?? 0,
                                  label: 'Followers',
                                  onTap: canNavigate
                                      ? () => openList(
                                          AppConstants.routes
                                              .followers(userId),
                                        )
                                      : null,
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                FollowStatButton(
                                  count: model?.followingCount ?? 0,
                                  label: 'Following',
                                  onTap: canNavigate
                                      ? () => openList(
                                          AppConstants.routes
                                              .following(userId),
                                        )
                                      : null,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bio preview
              if (model?.bio != null && model!.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
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
                        textAlign: TextAlign.left,
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
                ),
              ],
              const SizedBox(height: 12),
              // Hides itself on the logged-in user's own profile.
              FollowButton(targetId: helper.getId()),
            ],
          ),
        ),
      ),
    );
  }
}
