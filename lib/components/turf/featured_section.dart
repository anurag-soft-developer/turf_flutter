import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf/feed/turf_list_controller.dart';
import 'turf_cards.dart';

class FeaturedTurfsSection extends StatefulWidget {
  const FeaturedTurfsSection({super.key});

  @override
  State<FeaturedTurfsSection> createState() => _FeaturedTurfsSectionState();
}

class _FeaturedTurfsSectionState extends State<FeaturedTurfsSection> {
  final TurfListController _controller = Get.find<TurfListController>();
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final turfs = _controller.featuredTurfs;
      if (turfs.isEmpty) return const SizedBox.shrink();

      final activePage = _currentPage.clamp(0, turfs.length - 1);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              padEnds: false,
              controller: _pageController,
              itemCount: turfs.length,
              itemBuilder: (context, index) {
                return FeaturedTurfCard(
                  turf: turfs[index],
                  controller: _controller,
                );
              },
            ),
          ),
          if (turfs.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(turfs.length, (index) {
                final active = index == activePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(AppColors.primaryColor)
                        : const Color(AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      );
    });
  }
}
