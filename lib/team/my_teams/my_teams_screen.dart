import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/components/scroll/floating_sliver_app_bar.dart';
import '../../core/config/constants.dart';
import 'my_teams_memberships_body.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppConstants.routes.addTeam),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create team',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: MyTeamsMembershipsBody(
        leadingSlivers: [
          FloatingSliverAppBar(
            title: const Text('My Teams'),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () =>
                    Get.toNamed(AppConstants.routes.myTeamsSearch),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
