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

    return Obx(
      () => PopScope(
        canPop: !controller.isSubmitting.value,
        child: Scaffold(
          backgroundColor: const Color(AppColors.backgroundColor),
          appBar: AppBar(
            title: const Text('New Post'),
            backgroundColor: const Color(AppColors.primaryColor),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: LoadingOverlay(
            isLoading: controller.isSubmitting.value,
            message: controller.submitMessage.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CreatePostMediaPicker(files: controller.localFiles),
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
            ),
          ),
        ),
      ),
    );
  }
}
