import 'package:flutter_application_1/bindings/create_turf_binding.dart';
import 'package:flutter_application_1/bindings/manage_turf_binding.dart';
import 'package:flutter_application_1/bindings/turf_detail_binding.dart';
import 'package:flutter_application_1/bindings/turf_list_binding.dart';
import 'package:flutter_application_1/bindings/turf_management_binding.dart';
import 'package:flutter_application_1/bindings/turf_reviews_full_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/turf/create/create_turf_screen.dart';
import 'package:flutter_application_1/turf/details/turf_detail_screen.dart';
import 'package:flutter_application_1/turf/feed/turf_list_screen.dart';
import 'package:flutter_application_1/turf/my_turves/manage_turf_screen.dart';
import 'package:flutter_application_1/turf/my_turves/my_turfs_screen.dart';
import 'package:flutter_application_1/turf/reviews/turf_reviews_full_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> turfRoutes = [
  GetPage(
    name: AppConstants.routes.turfList,
    page: () => const TurfListScreen(),
    binding: TurfListBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.turfDetail,
    page: () => const TurfDetailScreen(),
    binding: TurfDetailBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.manageTurf,
    page: () => const ManageTurfScreen(),
    binding: ManageTurfBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.turfReviews,
    page: () => const TurfReviewsFullScreen(),
    binding: TurfReviewsFullBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.myTurfs,
    page: () => const MyTurfsScreen(),
    binding: TurfManagementBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.createTurf,
    page: () => const CreateTurfScreen(),
    binding: CreateTurfBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.editTurf,
    page: () => const CreateTurfScreen(),
    binding: CreateTurfBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
