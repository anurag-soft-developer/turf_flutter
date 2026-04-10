import 'package:flutter_application_1/core/views/legal/about_screen.dart';
import 'package:flutter_application_1/core/views/legal/help_support_screen.dart';
import 'package:flutter_application_1/core/views/legal/privacy_policy_screen.dart';
import 'package:flutter_application_1/core/views/legal/terms_of_service_screen.dart';
import 'package:get/get.dart';

import '../config/constants.dart';

/// About, help & support, terms of service, and privacy policy.
final List<GetPage<dynamic>> aboutHelpLegalRoutes = [
  GetPage(
    name: AppConstants.routes.about,
    page: () => const AboutScreen(),
    transition: Transition.cupertino,
  ),
  GetPage(
    name: AppConstants.routes.helpSupport,
    page: () => const HelpSupportScreen(),
    transition: Transition.cupertino,
  ),
  GetPage(
    name: AppConstants.routes.termsOfService,
    page: () => const TermsOfServiceScreen(),
    transition: Transition.cupertino,
  ),
  GetPage(
    name: AppConstants.routes.privacyPolicy,
    page: () => const PrivacyPolicyScreen(),
    transition: Transition.cupertino,
  ),
];
