import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/auth_state_controller.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/routes/app_routes.dart';
import 'package:get/get.dart';

class PublicGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthStateController>();

    if (authController.isLoggedIn) {
      return RouteSettings(name: AppRoutes.mainRoute);
    }
    return null; // Allow access
  }
}

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthStateController>();

    if (!authController.isLoggedIn) {
      return RouteSettings(name: AppConstants.routes.login);
    }
    return null; // Allow access
  }
}

class RoleGuard extends GetMiddleware {
  final List<String> allowedRoles;

  RoleGuard({required this.allowedRoles});

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthStateController>();

    if (!allowedRoles.contains(authController.user?.role)) {
      // Redirect to unauthorized page
      return RouteSettings(name: AppConstants.routes.accessDenied);
    }
    return null;
  }
}
