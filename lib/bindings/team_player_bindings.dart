import 'package:get/get.dart';

import '../team/add/add_team_controller.dart';
import '../team/details/team_detail_controller.dart';
import '../team/invites/team_invites_controller.dart';
import '../openings/openings_controller.dart';
import '../team/management/team_roster_manage_controller.dart';

class MyTeamsBinding extends Bindings {
  @override
  void dependencies() {}
}

class MyTeamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamDetailController>(
      () => TeamDetailController(isMyTeamMode: true),
    );
  }
}

class OpeningsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OpeningsController>(() => OpeningsController());
  }
}

class MyJoinRequestsBinding extends Bindings {
  @override
  void dependencies() {}
}

class OpeningRequestsBinding extends Bindings {
  @override
  void dependencies() {}
}

class TeamRosterManageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamRosterManageController>(() => TeamRosterManageController());
  }
}

class TeamInvitesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamInvitesController>(() => TeamInvitesController());
  }
}

class AddTeamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddTeamController>(() => AddTeamController(), fenix: true);
  }
}

class TeamProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamDetailController>(
      () => TeamDetailController(isMyTeamMode: false),
    );
  }
}
