import 'package:flutter_application_1/core/auth/forgot_password/forgot_password_screen.dart';
import 'package:flutter_application_1/core/auth/login/login_screen.dart';
import 'package:flutter_application_1/core/auth/signup/signup_screen.dart';
import 'package:flutter_application_1/core/binding/auth_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:get/get.dart';

/// Login, signup, and password recovery (public routes).
final List<GetPage<dynamic>> authRoutes = [
  GetPage(
    name: AppConstants.routes.login,
    page: () => const LoginScreen(),
    binding: LoginBinding(),
    transition: Transition.cupertino,
    middlewares: [PublicGuard()],
  ),
  GetPage(
    name: AppConstants.routes.signup,
    page: () => const SignupScreen(),
    binding: SignupBinding(),
    transition: Transition.cupertino,
    middlewares: [PublicGuard()],
  ),
  GetPage(
    name: AppConstants.routes.forgotPassword,
    page: () => const ForgotPasswordScreen(),
    transition: Transition.cupertino,
  ),
];
