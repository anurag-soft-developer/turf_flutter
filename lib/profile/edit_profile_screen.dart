import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/avatar_image_input.dart';
import '../components/shared/custom_button.dart';
import '../components/shared/custom_text_field.dart';
import '../components/shared/loading_overlay.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/config/constants.dart';
import '../core/models/media_upload_models.dart';
import '../core/utils/validators.dart';
import 'profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    final AuthStateController authController = Get.find<AuthStateController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(
        () => LoadingOverlay(
          isLoading: profileController.isLoading,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(AppColors.primaryColor),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 30,
                      top: 8,
                    ),
                    child: Obx(
                      () => AvatarImageInput(
                        imageUrls: profileController.avatarImageUrls,
                        fallbackUrl: authController.user?.avatar,
                        placeholderIcon: Icons.person,
                        uploadPurpose: MediaUploadPurpose.avatar,
                        onChange: (urls) async {
                          if (urls.isEmpty) return;
                          await authController.updateUserProfile(
                            avatar: urls.first,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Form Fields
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: profileController.profileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        CustomTextField(
                          controller: profileController.fullNameController,
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                          validator: Validators.validateName,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 24),

                        if (authController.user?.email != null &&
                            authController.user!.email!.isNotEmpty) ...[
                          CustomTextField(
                            controller: profileController.emailController,
                            labelText: 'Email',
                            enabled: false,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (authController.user?.phone != null &&
                            authController.user!.phone!.isNotEmpty) ...[
                          CustomTextField(
                            controller: profileController.phoneController,
                            labelText: 'Phone',
                            enabled: false,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Bio
                        CustomTextField(
                          controller: profileController.bioController,
                          labelText: 'Bio',
                          hintText: 'Tell us about yourself',
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                          maxLength: 500,
                          prefixIcon: const Icon(
                            Icons.description_outlined,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel',
                                isOutlined: true,
                                onPressed: () => Get.back(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomButton(
                                text: 'Save',
                                onPressed: () async {
                                  final result = await profileController
                                      .updateProfile();
                                  if (result != null) {
                                    Get.back();
                                  }
                                },
                                isLoading: profileController.isLoading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
