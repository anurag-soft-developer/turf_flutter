import 'package:flutter_application_1/bindings/turf_detail_binding.dart';
import 'package:flutter_application_1/bindings/turf_list_binding.dart';
import 'package:flutter_application_1/bindings/turf_reviews_full_binding.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/turf/details/turf_detail_screen.dart';
import 'package:flutter_application_1/turf/feed/turf_list_screen.dart';
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
    name: AppConstants.routes.turfReviews,
    page: () => const TurfReviewsFullScreen(),
    binding: TurfReviewsFullBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
