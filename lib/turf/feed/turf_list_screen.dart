import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/user_avatar_app_bar_action.dart';
import 'package:get/get.dart';
import 'turf_list_controller.dart';
import '../../components/turf/search_components.dart';
import '../../components/turf/turf_cards.dart';
import '../../components/turf/filter_bottom_sheet.dart';
import '../../core/config/constants.dart';

class TurfListScreen extends StatelessWidget {
  const TurfListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TurfListController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const UserAvatarAppBarAction(),
        title: const Text(
          'Find Turfs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => FilterBottomSheet.show(context, controller),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: controller.refreshTurfs,
            child: Column(
              children: [
                // Search Section
                TurfSearchSection(controller: controller),

                // Turfs List
                Expanded(child: _buildTurfsList(controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurfsList(TurfListController controller) {
    return Obx(() {
      if (controller.turfs.isEmpty && controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(AppColors.primaryColor),
            ),
          ),
        );
      }

      if (controller.turfs.isEmpty && !controller.isLoading.value) {
        return EmptyTurfsView(onClearFilters: controller.clearFilters);
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            controller.loadMoreTurfs();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.turfs.length +
              (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.turfs.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppColors.primaryColor),
                    ),
                  ),
                ),
              );
            }

            final turf = controller.turfs[index];
            return TurfListCard(turf: turf, controller: controller);
          },
        ),
      );
    });
  }
}
