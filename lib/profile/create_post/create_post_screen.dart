import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/shared/custom_button.dart';
import '../../components/shared/custom_text_field.dart';
import '../../components/shared/loading_overlay.dart';
import '../../core/config/constants.dart';
import 'create_post_controller.dart';
import 'widgets/create_post_media_picker.dart';

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
                appBar: AppBar(
                  title: Text(
                    step == CreatePostStep.caption ? 'New Post' : 'Add photos',
                  ),
                  backgroundColor: const Color(AppColors.primaryColor),
                  foregroundColor: Colors.white,
                  elevation: 0,
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
