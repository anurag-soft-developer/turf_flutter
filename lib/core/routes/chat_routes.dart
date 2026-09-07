import 'package:flutter_application_1/chat/chat_inbox_screen.dart';
import 'package:flutter_application_1/chat/chat_inbox_search_screen.dart';
import 'package:flutter_application_1/chat/chat_thread_screen.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/guards/auth_guard.dart';
import 'package:get/get.dart';

final List<GetPage<dynamic>> chatRoutes = [
  GetPage(
    name: AppConstants.routes.chatInbox,
    page: () => const ChatInboxScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.chatInboxSearch,
    page: () => const ChatInboxSearchScreen(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
  GetPage(
    name: AppConstants.routes.chatThread,
    page: () => ChatThreadScreen.fromRoute(),
    transition: Transition.cupertino,
    middlewares: [AuthGuard()],
  ),
];
