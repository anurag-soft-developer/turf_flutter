import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/shared/loading_overlay.dart';
import '../../components/turf/turf_detail_scroll_content.dart';
import '../../core/config/constants.dart';
import '../details/turf_detail_controller.dart';
import '../model/turf_model.dart';
import 'turf_management_controller.dart';

class ManageTurfScreen extends StatelessWidget {
  const ManageTurfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TurfDetailController detailController = Get.find();
    final TurfManagementController managementController = Get.find();

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: Obx(() {
        // Read every Rx this screen depends on here so one Obx subscribes cleanly
        // (nested Obx + action buttons was tripping GetX improper-use detection).
        final turf = detailController.turf.value;
        final detailLoading = detailController.isLoading.value;
        final managementLoading = managementController.isLoading.value;

        return Stack(
          children: [
            turf == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(AppColors.primaryColor),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: detailController.refreshData,
                    child: TurfDetailScrollContent(
                      controller: detailController,
                      showBookingSection: false,
                      showReviewList: false,
                      belowReviews: _ManageTurfActions(
                        turf: turf,
                        managementController: managementController,
                        managementLoading: managementLoading,
                      ),
                    ),
                  ),
            if (detailLoading)
              const LoadingOverlay(isLoading: true, child: SizedBox()),
          ],
        );
      }),
    );
  }
}

class _ManageTurfActions extends StatelessWidget {
  final TurfModel turf;
  final TurfManagementController managementController;
  final bool managementLoading;

  const _ManageTurfActions({
    required this.turf,
    required this.managementController,
    required this.managementLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = turf.isAvailable == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Manage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textColor),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => managementController.navigateToEditTurf(turf),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit turf'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(AppColors.primaryColor),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: managementLoading
                ? null
                : () => managementController.toggleTurfAvailability(turf),
            icon: Icon(
              isAvailable
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            label: Text(isAvailable ? 'Deactivate' : 'Activate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isAvailable
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
              side: BorderSide(
                color: isAvailable ? Colors.orange : Colors.green,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: managementLoading
                ? null
                : () async {
                    final deleted = await managementController.deleteTurf(turf);
                    if (deleted) Get.back();
                  },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete turf'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
