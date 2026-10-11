import 'package:get/get.dart';

import 'my_invitations_controller.dart';

class MyInvitationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyInvitationsController>(() => MyInvitationsController());
  }
}
