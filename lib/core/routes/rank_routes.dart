import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:flutter_application_1/rankings/rank_binding.dart';
import 'package:flutter_application_1/rankings/rank_screen.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> rankRoutes = [
  GetPage(
    name: AppConstants.routes.rank,
    page: () => const RankScreen(),
    binding: RankBinding(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
