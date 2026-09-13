import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/match_up/team_logo.dart';
import '../../components/shared/app_network_image.dart';
import '../../components/shared/custom_button.dart';
import '../../components/shared/custom_text_field.dart';
import '../../components/shared/loading_overlay.dart';
import '../../core/components/app_bar/app_bar_background.dart';
import '../../core/config/constants.dart';
import 'create_post_controller.dart';
import 'widgets/create_post_media_picker.dart';
import 'widgets/create_post_mention_sheet.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreatePostController>();

    return Obx(() {
      final step = controller.step.value;
      final submitting = controller.isSubmitting.value;

      return PopScope(
        canPop: !submitting && step != CreatePostStep.edit,
        child: step == CreatePostStep.edit
            ? const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Scaffold(
                backgroundColor: const Color(AppColors.backgroundColor),
                appBar: AppAppBar(
                  title: Text(
                    step == CreatePostStep.caption ? 'New Post' : 'Add photos',
                  ),
                ),
                body: step == CreatePostStep.caption
                    ? LoadingOverlay(
                        isLoading: submitting,
                        message: controller.submitMessage.value,
                        child: _CaptionStep(controller: controller),
                      )
                    : _PickStep(controller: controller),
              ),
      );
    });
  }
}

class _PickStep extends StatelessWidget {
  final CreatePostController controller;

  const _PickStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: CreatePostMediaPicker(
        files: controller.localFiles,
        maxImages: CreatePostController.maxImages,
        autoOpenSource: true,
        onPicked: controller.onPhotosPicked,
      ),
    );
  }
}

class _CaptionStep extends StatelessWidget {
  final CreatePostController controller;

  const _CaptionStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CreatePostMediaPicker(
              files: controller.localFiles,
              maxImages: CreatePostController.maxImages,
              onPicked: controller.onPhotosPicked,
              onFileRemoved: controller.onEditedFileRemoved,
              onEdit: controller.reEditAt,
              focusIndex: controller.previewIndex,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: controller.captionController,
            labelText: 'Caption (optional)',
            hintText: 'Say something about these photos',
            minLines: 3,
            maxLength: 2000,
            keyboardType: TextInputType.multiline,
            prefixIcon: const Icon(
              Icons.notes_outlined,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 16),
          _CreatePostMentions(controller: controller),
          const SizedBox(height: 28),
          CustomButton(
            text: 'Publish',
            icon: const Icon(Icons.publish_outlined, size: 20),
            onPressed: controller.submit,
            isLoading: controller.isSubmitting.value,
          ),
        ],
      ),
    );
  }
}

class _CreatePostMentions extends StatelessWidget {
  const _CreatePostMentions({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tag (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 8),
          _MentionCard(
            emptyLabel: 'Team',
            emptyHint: 'Tag a team',
            icon: Icons.groups_outlined,
            mention: controller.mentionedTeam.value,
            onTap: () => controller.pickTeam(context),
            onClear: () => controller.mentionedTeam.value = null,
          ),
          const SizedBox(height: 8),
          _MentionCard(
            emptyLabel: 'Match',
            emptyHint: 'Tag a match',
            icon: Icons.sports_outlined,
            mention: controller.mentionedMatch.value,
            isMatch: true,
            onTap: () => controller.pickMatch(context),
            onClear: () => controller.mentionedMatch.value = null,
          ),
          const SizedBox(height: 8),
          _MentionCard(
            emptyLabel: 'Turf',
            emptyHint: 'Tag a turf',
            icon: AppIcons.turfPlaceholder,
            mention: controller.mentionedTurf.value,
            isTurf: true,
            onTap: () => controller.pickTurf(context),
            onClear: () => controller.mentionedTurf.value = null,
          ),
        ],
      );
    });
  }
}

class _MentionCard extends StatelessWidget {
  const _MentionCard({
    required this.emptyLabel,
    required this.emptyHint,
    required this.icon,
    required this.mention,
    required this.onTap,
    required this.onClear,
    this.isMatch = false,
    this.isTurf = false,
  });

  final String emptyLabel;
  final String emptyHint;
  final IconData icon;
  final PostMentionRef? mention;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool isMatch;
  final bool isTurf;

  @override
  Widget build(BuildContext context) {
    final selected = mention != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(AppColors.primaryColor).withValues(alpha: 0.35)
                  : const Color(AppColors.dividerColor),
            ),
          ),
          child: Row(
            children: [
              _leading(),
              const SizedBox(width: 12),
              Expanded(
                child: selected
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mention!.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                          if ((mention!.subtitle ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              mention!.subtitle!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(AppColors.textSecondaryColor),
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emptyLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(AppColors.textColor),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emptyHint,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
              ),
              if (selected)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(AppColors.textSecondaryColor),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Color(AppColors.primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leading() {
    if (mention != null && isMatch) {
      return CreatePostMatchPairLogos(
        leftUrl: mention!.imageUrl,
        rightUrl: mention!.secondaryImageUrl,
        size: 36,
      );
    }
    if (isTurf) {
      return _TurfAvatar(url: mention?.imageUrl);
    }
    return TeamLogo(
      url: mention?.imageUrl ?? '',
      size: 40,
    );
  }
}

class _TurfAvatar extends StatelessWidget {
  const _TurfAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: url == null || url!.isEmpty
            ? Container(
                color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
                child: const Icon(
                  AppIcons.turfPlaceholder,
                  color: Color(AppColors.primaryColor),
                ),
              )
            : AppNetworkImage(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.1),
                  child: const Icon(
                    AppIcons.turfPlaceholder,
                    color: Color(AppColors.primaryColor),
                  ),
                ),
              ),
      ),
    );
  }
}

