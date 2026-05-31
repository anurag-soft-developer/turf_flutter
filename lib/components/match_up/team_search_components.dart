import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/constants.dart';
import '../../match_up/match_up_controller.dart';
import '../shared/custom_text_field.dart';

class TeamSearchBar extends StatelessWidget {
  const TeamSearchBar({super.key, required this.controller});

  final MatchUpController controller;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      hintText: 'Search teams by name',
      prefixIcon: const Icon(Icons.search, color: Colors.grey),
      suffixIcon: Obx(
        () => controller.isSearching.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                onPressed: controller.searchTeams,
                icon: const Icon(Icons.send),
              ),
      ),
    );
  }
}

class TeamSearchSection extends StatelessWidget {
  const TeamSearchSection({super.key, required this.controller});

  final MatchUpController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(AppColors.primaryColor),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: TeamSearchBar(controller: controller),
    );
  }
}
