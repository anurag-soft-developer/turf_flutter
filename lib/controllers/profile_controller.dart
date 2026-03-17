import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'auth/auth_state_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final AuthStateController _authController = AuthStateController.instance;

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form key
  final GlobalKey<FormState> profileFormKey = GlobalKey<FormState>();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;

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
    }
  }

  void toggleEdit() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      _loadUserData(); // Reset to original values if cancelling edit
    }
  }

  Future<void> updateProfile() async {
    if (!profileFormKey.currentState!.validate()) return;

    _isLoading.value = true;

    await _authController.updateUserProfile(
      fullName: fullNameController.text.trim(),
      bio: bioController.text.trim(),
      phone: phoneController.text.trim().isNotEmpty
          ? phoneController.text.trim()
          : null,
    );

    _isEditing.value = false;
    _isLoading.value = false;
  }

  void refreshProfile() {
    _loadUserData();
    update();
  }
}
