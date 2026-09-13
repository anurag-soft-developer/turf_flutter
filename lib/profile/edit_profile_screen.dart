import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../components/shared/app_network_image.dart';
import '../components/shared/custom_text_field.dart';
import '../components/shared/form_bottom_actions.dart';
import '../components/shared/loading_overlay.dart';
import '../core/auth/auth_state_controller.dart';
import '../core/components/app_bar/app_bar_background.dart';
import '../core/config/constants.dart';
import '../core/media/local_image_pipeline.dart';
import '../core/utils/validators.dart';
import 'profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<ProfileController>().refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    final AuthStateController authController = Get.find<AuthStateController>();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppAppBar(title: const Text('Edit Profile')),
      body: Obx(
        () => LoadingOverlay(
          isLoading: profileController.isLoading,
          message: profileController.submitMessage.value,
          child: Column(
            children: [
              Expanded(
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
                            () => _DeferredAvatarPicker(
                              draft: profileController.avatarDraft.value,
                              onPick: profileController.setAvatarFromPick,
                              onReEdit: profileController.reEditAvatar,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: profileController.profileFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   'Personal Information',
                              //   style: TextStyle(
                              //     fontSize: 20,
                              //     fontWeight: FontWeight.bold,
                              //     color: Color(AppColors.textColor),
                              //   ),
                              // ),
                              const SizedBox(height: 24),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FormBottomActions(
                secondaryLabel: 'Cancel',
                onSecondary: () => Get.back(),
                primaryLabel: 'Save',
                isLoading: profileController.isLoading,
                onPrimary: () => profileController.updateProfile(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local-only avatar picker; uploads happen on Save via [ProfileController].
class _DeferredAvatarPicker extends StatefulWidget {
  final LocalImageDraft? draft;
  final Future<void> Function(XFile file) onPick;
  final Future<void> Function() onReEdit;

  const _DeferredAvatarPicker({
    required this.draft,
    required this.onPick,
    required this.onReEdit,
  });

  @override
  State<_DeferredAvatarPicker> createState() => _DeferredAvatarPickerState();
}

class _DeferredAvatarPickerState extends State<_DeferredAvatarPicker> {
  final ImagePicker _picker = ImagePicker();

  void _showSourceSheet() {
    ImageSourcePicker.showSourceSheet(
      title: 'Profile photo',
      onCamera: () => _pick(ImageSource.camera),
      onGallery: () => _pick(ImageSource.gallery),
      isMounted: () => mounted,
    );
  }

  Future<void> _pick(ImageSource source) async {
    final image = await ImageSourcePicker.pickSingle(
      picker: _picker,
      source: source,
    );
    if (!mounted || image == null) return;
    await widget.onPick(image);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: draft == null ? _showSourceSheet : widget.onReEdit,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                key: ValueKey(
                  draft?.localFile?.path ?? draft?.remoteUrl ?? 'empty',
                ),
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _avatarImage(draft),
                child: _avatarImage(draft) == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(AppColors.primaryColor),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _showSourceSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(AppColors.primaryColor),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Color(AppColors.primaryColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _avatarImage(LocalImageDraft? draft) {
    final file = draft?.localFile;
    if (file != null) return FileImage(File(file.path));
    final url = draft?.remoteUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return AppNetworkImage.provider(url);
  }
}
