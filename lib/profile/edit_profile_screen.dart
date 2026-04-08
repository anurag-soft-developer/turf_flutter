import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/shared/custom_button.dart';
import '../components/shared/custom_text_field.dart';
import '../components/shared/loading_overlay.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/config/constants.dart';
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
                // Avatar Section
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
                    child: Center(
                      child: Stack(
                        children: [
                          Obx(
                            () => CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  authController.user?.avatar != null
                                  ? NetworkImage(authController.user!.avatar!)
                                  : null,
                              child: authController.user?.avatar == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(AppColors.primaryColor),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(AppColors.primaryColor),
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Color(AppColors.primaryColor),
                                  size: 18,
                                ),
                                onPressed: () {
                                  Get.snackbar(
                                    'Coming Soon',
                                    'Photo upload will be available soon',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
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
                        ),
                        const SizedBox(height: 24),

                        // Bio
                        CustomTextField(
                          controller: profileController.bioController,
                          labelText: 'Bio',
                          hintText: 'Tell us about yourself',
                          maxLines: 3,
                          prefixIcon: const Icon(
                            Icons.description_outlined,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email (read-only)
                        // CustomTextField(
                        //   controller: profileController.emailController,
                        //   labelText: 'Email',
                        //   hintText: 'Your email address',
                        //   readOnly: true,
                        //   prefixIcon: const Icon(
                        //     Icons.email_outlined,
                        //     color: Color(AppColors.textSecondaryColor),
                        //   ),
                        //   suffixIcon:
                        //       authController.user?.isEmailVerified == true
                        //           ? const Icon(
                        //               Icons.verified,
                        //               color: Color(AppColors.successColor),
                        //             )
                        //           : null,
                        // ),
                        // const SizedBox(height: 24),

                        // Phone
                        CustomTextField(
                          controller: profileController.phoneController,
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
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
                                text: 'Save Changes',
                                onPressed: () async {
                                  await profileController.updateProfile();
                                  if (!profileController.isLoading) {
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
