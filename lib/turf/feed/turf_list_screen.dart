import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/shared/app_drawer.dart';
import 'package:get/get.dart';
import 'turf_list_controller.dart';
import '../../components/shared/loading_overlay.dart';
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
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
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
          // Loading overlay for initial load only
          Obx(
            () => controller.isLoading.value && controller.turfs.isEmpty
                ? const LoadingOverlay(isLoading: true, child: SizedBox())
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildTurfsList(TurfListController controller) {
    return Obx(() {
      // Check if list is empty and not loading
      if (controller.turfs.isEmpty && !controller.isLoading.value) {
        return EmptyTurfsView(onClearFilters: controller.clearFilters);
      }

      // Show the list
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount:
            controller.turfs.length + (controller.hasMoreData.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.turfs.length) {
            // Load more indicator
            controller.loadMoreTurfs();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final turf = controller.turfs[index];
          return TurfListCard(turf: turf, controller: controller);
        },
      );
    });
  }
}
