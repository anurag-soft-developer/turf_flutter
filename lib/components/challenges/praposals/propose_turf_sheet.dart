import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../turf/model/turf_model.dart';
import 'propose_turf_sheet_controller.dart';

class ProposeTurfSheet extends StatelessWidget {
  final List<String>? sportTypes;

  const ProposeTurfSheet({super.key, this.sportTypes});

  @override
  Widget build(BuildContext context) {
    final tag = 'propose_turf_${sportTypes?.join('_') ?? 'all'}';
    final controller = Get.isRegistered<ProposeTurfSheetController>(tag: tag)
        ? Get.find<ProposeTurfSheetController>(tag: tag)
        : Get.put(
            ProposeTurfSheetController(sportTypes: sportTypes),
            tag: tag,
          );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && Get.isRegistered<ProposeTurfSheetController>(tag: tag)) {
          Get.delete<ProposeTurfSheetController>(tag: tag);
        }
      },
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Turf',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: controller.searchController,
                      style: const TextStyle(color: Color(AppColors.textColor)),
                      decoration: InputDecoration(
                        hintText: 'Search turf by name or address',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(AppColors.backgroundColor),
                        suffixIcon: controller.searchQuery.value.isEmpty
                            ? null
                            : IconButton(
                                onPressed: controller.clearSearch,
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: Obx(() => _buildTurfList(controller))),
                  const SizedBox(height: 12),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.selectedTurfId.value == null ||
                                controller.isLoading.value
                            ? null
                            : () => Navigator.of(context)
                                .pop(controller.selectedTurfId.value),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurfList(ProposeTurfSheetController controller) {
    if (controller.isLoading.value && controller.turfs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.turfs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No turfs found. Try a different search.',
          style: TextStyle(color: Color(AppColors.textSecondaryColor)),
        ),
      );
    }

    return Stack(
      children: [
        RadioGroup<String>(
          groupValue: controller.selectedTurfId.value,
          onChanged: controller.selectTurf,
          child: ListView.separated(
            itemCount: controller.turfs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final turf = controller.turfs[index];
              return _TurfTile(
                turf: turf,
                onTap: () => controller.selectTurf(turf.id),
              );
            },
          ),
        ),
        if (controller.isLoading.value)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _TurfTile extends StatelessWidget {
  const _TurfTile({required this.turf, required this.onTap});

  final TurfModel turf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final turfId = turf.id ?? '';
    final isSelectable = turfId.isNotEmpty;

    return InkWell(
      onTap: !isSelectable ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: turf.mainImage != null
                  ? Image.network(
                      turf.mainImage!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turf.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  if (turf.location?.address != null)
                    Text(
                      turf.location!.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                ],
              ),
            ),
            isSelectable
                ? Radio<String>(value: turfId)
                : const Icon(Icons.block, size: 20, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
