import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/signup_controller.dart';
import '../../controllers/auth/auth_state_controller.dart';
import '../../components/shared/custom_button.dart';
import '../../components/shared/custom_text_field.dart';
import '../../components/shared/loading_overlay.dart';
import '../../utils/validators.dart';
import '../../config/constants.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SignupController signupController = Get.find();
    final AuthStateController authStateController = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: Obx(
        () => LoadingOverlay(
          isLoading:
              signupController.isLoading || authStateController.isLoading,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: signupController.signupFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Header
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Full Name Field
                    CustomTextField(
                      controller: signupController.fullNameController,
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    CustomTextField(
                      controller: signupController.emailController,
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    CustomTextField(
                      controller: signupController.passwordController,
                      labelText: 'Password',
                      hintText: 'Create a password',
                      obscureText: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 24),

                    // Confirm Password Field
                    CustomTextField(
                      controller: signupController.confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      obscureText: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        signupController.passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Phone Number Field (Optional)
                    CustomTextField(
                      controller: signupController.phoneController,
                      labelText: 'Phone Number (Optional)',
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Color(AppColors.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Terms and Conditions
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(AppColors.textSecondaryColor),
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By creating an account, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: Color(AppColors.primaryColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Color(AppColors.primaryColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign Up Button
                    CustomButton(
                      text: 'Create Account',
                      onPressed: signupController.signUp,
                      isLoading: signupController.isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: const Color(AppColors.textSecondaryColor),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Sign In Button
                    CustomButton(
                      text: 'Continue with Google',
                      onPressed: authStateController.signInWithGoogle,
                      isOutlined: true,
                      icon: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://developers.google.com/identity/images/g-logo.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Sign In Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                          TextButton(
                            onPressed: signupController.goToLogin,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(AppColors.primaryColor),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
