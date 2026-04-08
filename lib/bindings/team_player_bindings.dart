import 'package:get/get.dart';

import '../team/add/add_team_controller.dart';
import '../team/details/team_detail_controller.dart';
import '../team/feed/teams_ranking_controller.dart';
import '../team/my_teams/my_teams_controller.dart';

class MyTeamsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyTeamsController>(() => MyTeamsController());
  }
}

class MyTeamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamDetailController>(
      () => TeamDetailController(isMyTeamMode: true),
    );
  }
}

class TeamsRankingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamsRankingController>(() => TeamsRankingController());
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
