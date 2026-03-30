import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/auth_state_controller.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';
import '../components/shared/custom_button.dart';
import '../components/shared/custom_text_field.dart';
import '../components/shared/loading_overlay.dart';
import '../core/utils/validators.dart';
import '../core/config/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());
    final AuthStateController authController = Get.find<AuthStateController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              onPressed: profileController.isEditing
                  ? null
                  : profileController.toggleEdit,
              icon: Icon(
                profileController.isEditing ? Icons.edit_off : Icons.edit,
              ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => LoadingOverlay(
          isLoading: profileController.isLoading,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  authController.user?.avatar != null
                                  ? NetworkImage(authController.user!.avatar!)
                                  : null,
                              child: authController.user?.avatar == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(AppColors.primaryColor),
                                    )
                                  : null,
                            ),
                            if (profileController.isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        AppColors.primaryColor,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Color(AppColors.primaryColor),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement image picker
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
                        const SizedBox(height: 16),

                        // User Name
                        Text(
                          authController.user?.fullName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // User Email
                        Text(
                          authController.user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Verification Badge
                        if (authController.user?.isEmailVerified == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(AppColors.successColor),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Profile Form
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

                        // Full Name Field
                        CustomTextField(
                          controller: profileController.fullNameController,
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          readOnly: !profileController.isEditing,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 24),

                        // Bio Field
                        CustomTextField(
                          controller: profileController.bioController,
                          labelText: 'Bio',
                          hintText: 'Tell us about yourself',
                          readOnly: !profileController.isEditing,
                          maxLines: 3,
                          prefixIcon: const Icon(
                            Icons.description_outlined,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        CustomTextField(
                          controller: profileController.emailController,
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          readOnly: true, // Email should not be editable
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                          suffixIcon:
                              authController.user?.isEmailVerified == true
                              ? const Icon(
                                  Icons.verified,
                                  color: Color(AppColors.successColor),
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Phone Field
                        CustomTextField(
                          controller: profileController.phoneController,
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          readOnly: !profileController.isEditing,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(AppColors.textSecondaryColor),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        if (profileController.isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Cancel',
                                  isOutlined: true,
                                  onPressed: profileController.toggleEdit,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: 'Save Changes',
                                  onPressed: profileController.updateProfile,
                                  isLoading: profileController.isLoading,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Account Information Section
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'User ID',
                                  authController.user?.id?.substring(0, 8) ??
                                      'N/A',
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Account Created',
                                  authController.user?.createdAtDate != null
                                      ? '${authController.user!.createdAtDate!.day}/${authController.user!.createdAtDate!.month}/${authController.user!.createdAtDate!.year}'
                                      : 'Unknown',
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Last Sign In',
                                  authController.user?.lastLoginDate != null
                                      ? '${authController.user!.lastLoginDate!.day}/${authController.user!.lastLoginDate!.month}/${authController.user!.lastLoginDate!.year}'
                                      : 'Unknown',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Account Actions
                        const Text(
                          'Account Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(AppColors.textColor),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.lock_outline,
                                  color: Color(AppColors.primaryColor),
                                ),
                                title: const Text('Change Password'),
                                subtitle: const Text('Update your password'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Get.snackbar(
                                    'Coming Soon',
                                    'Password change will be available soon',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.download,
                                  color: Color(AppColors.primaryColor),
                                ),
                                title: const Text('Download Data'),
                                subtitle: const Text(
                                  'Export your account data',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Get.snackbar(
                                    'Coming Soon',
                                    'Data download will be available soon',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Delete Account',
                                  style: TextStyle(color: Colors.red),
                                ),
                                subtitle: const Text(
                                  'Permanently delete your account',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _showDeleteAccountDialog(context),
                              ),
                            ],
                          ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textColor),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Coming Soon',
                'Account deletion will be available soon',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
