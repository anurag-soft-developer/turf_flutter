import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../turf/feed/turf_list_controller.dart';
import 'turf_cards.dart';

class FeaturedTurfsSection extends StatelessWidget {
  final TurfListController controller = Get.find<TurfListController>();

  FeaturedTurfsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.featuredTurfs.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              padEnds: false,
              controller: PageController(
                viewportFraction: 1.0, // Show full width items
              ),
              itemCount: controller.featuredTurfs.length,
              itemBuilder: (context, index) {
                final turf = controller.featuredTurfs[index];
                return FeaturedTurfCard(turf: turf, controller: controller);
              },
            ),
          ),
        ],
      );
    });
  }
}
