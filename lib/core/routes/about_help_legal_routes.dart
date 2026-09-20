import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/core/views/legal/about_screen.dart';
import 'package:flutter_application_1/core/views/legal/help_support_screen.dart';
import 'package:flutter_application_1/core/views/legal/privacy_policy_screen.dart';
import 'package:flutter_application_1/core/views/legal/support_queries_history_screen.dart';
import 'package:flutter_application_1/core/views/legal/support_query_detail_screen.dart';
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
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.supportQueries,
    page: () => const SupportQueriesHistoryScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: '/help-support/queries/:id',
    page: () => SupportQueryDetailScreen(
      queryId: Get.parameters['id'] ?? '',
    ),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
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
