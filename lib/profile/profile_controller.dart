import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../core/auth/auth_state_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final AuthStateController _authController = AuthStateController.instance;

  /// URLs bound to [ImageInput] for avatar (single slot). Synced from user in [_loadUserData].
  final RxList<String> avatarImageUrls = <String>[].obs;

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form key
  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();

  // Observable variables
  final RxBool _isLoading = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    bioController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final user = _authController.user;
    if (user != null) {
      fullNameController.text = user.fullName ?? '';
      bioController.text = user.bio ?? '';
      emailController.text = user.email ?? '';
      phoneController.text = user.phone ?? '';
      avatarImageUrls
        ..clear()
        ..addAll(
          user.avatar != null && user.avatar!.isNotEmpty ? [user.avatar!] : [],
        );
    } else {
      avatarImageUrls.clear();
    }
  }

  Future<UserModel?> updateProfile() async {
    if (!profileFormKey.currentState!.validate()) return null;

    _isLoading.value = true;

    final result = await _authController.updateUserProfile(
      fullName: fullNameController.text.trim(),
      bio: bioController.text.trim(),
      phone: phoneController.text.trim(),
    );

    _isLoading.value = false;

    return result;
  }

  void refreshProfile() {
    _loadUserData();
    update();
  }
}
