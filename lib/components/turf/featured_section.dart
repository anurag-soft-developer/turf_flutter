import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/constants.dart';
import '../../turf/feed/turf_list_controller.dart';
import '../shared/breathing_skeleton.dart';
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

  static const double _viewportFraction = 0.88;
  static const double _itemHorizontalPadding = 6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
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
      final isLoading = _controller.isFeaturedLoading.value;

      if (isLoading && turfs.isEmpty) {
        return _FeaturedTurfsSkeleton(
          viewportFraction: _viewportFraction,
          itemHorizontalPadding: _itemHorizontalPadding,
        );
      }

      if (turfs.isEmpty) return const SizedBox.shrink();

      final activePage = _currentPage.clamp(0, turfs.length - 1);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: turfs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _itemHorizontalPadding,
                  ),
                  child: FeaturedTurfCard(
                    turf: turfs[index],
                    controller: _controller,
                  ),
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

class _FeaturedTurfsSkeleton extends StatelessWidget {
  const _FeaturedTurfsSkeleton({
    required this.viewportFraction,
    required this.itemHorizontalPadding,
  });

  final double viewportFraction;
  final double itemHorizontalPadding;

  static const _cardRadius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    return BreathingSkeleton(
      builder: (opacity) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth * viewportFraction;

            return SizedBox(
              height: 200,
              child: Center(
                child: SizedBox(
                  width: pageWidth,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: itemHorizontalPadding,
                    ),
                    child: Card(
                  elevation: 4,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BreathingBlock(
                        opacity: opacity,
                        borderRadius: BorderRadius.zero,
                        color: const Color(AppColors.primaryColor),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.78),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            BreathingBlock(
                              opacity: opacity,
                              width: 168,
                              height: 16,
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                BreathingCircle(
                                  opacity: opacity,
                                  size: 15,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: BreathingBlock(
                                    opacity: opacity,
                                    height: 12,
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                BreathingBlock(
                                  opacity: opacity,
                                  width: 64,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}
