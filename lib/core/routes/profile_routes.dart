import 'package:flutter_application_1/bindings/edit_profile_binding.dart';
import 'package:flutter_application_1/bindings/profile_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/profile/edit_profile_screen.dart';
import 'package:flutter_application_1/profile/profile_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> profileRoutes = [
  GetPage(
    name: AppConstants.routes.profile,
    page: () => const ProfileScreen(),
    binding: ProfileBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.editProfile,
    page: () => const EditProfileScreen(),
    binding: EditProfileBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
