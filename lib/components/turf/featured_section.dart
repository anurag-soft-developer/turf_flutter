import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';
import '../../controllers/turf_list_controller.dart';
import 'turf_cards.dart';

class FeaturedTurfsSection extends StatelessWidget {
  final TurfListController controller;

  const FeaturedTurfsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.featuredTurfs.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Featured Turfs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: controller.featuredTurfs.length,
                itemBuilder: (context, index) {
                  final turf = controller.featuredTurfs[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16),
                    child: FeaturedTurfCard(turf: turf, controller: controller),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
