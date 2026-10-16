import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/components/scroll/floating_sliver_app_bar.dart';
import '../core/components/scroll/pinned_sliver_header.dart';
import '../core/config/constants.dart';
import '../team/model/team_model.dart';
import 'model/opening_model.dart';
import 'opening_manage.dart';
import 'openings_controller.dart';

class MyOpeningsScreen extends StatefulWidget {
  const MyOpeningsScreen({super.key});

  @override
  State<MyOpeningsScreen> createState() => _MyOpeningsScreenState();
}

class _MyOpeningsScreenState extends State<MyOpeningsScreen> {
  late final OpeningsController _controller;
  TeamSportType? _sport;
  OpeningType? _type;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<OpeningsController>();
    _controller.loadOwnedOpenings();
  }

  List<ManagedOpening> _visible(List<ManagedOpening> items) {
    return [
      for (final item in items)
        if (_matches(item)) item,
    ];
  }

  bool _matches(ManagedOpening item) {
    if (_type != null && item.host.type != _type) return false;
    final sport = _sport;
    if (sport != null && item.host.sportType != sport.name) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      floatingActionButton: Obx(() {
        if (_controller.postableHosts.isEmpty) return const SizedBox.shrink();
        return FloatingActionButton(
          tooltip: 'Post opening',
          backgroundColor: const Color(AppColors.primaryColor),
          foregroundColor: Colors.white,
          onPressed: () => showPostOpeningSheet(context, _controller),
          child: const Icon(Icons.add),
        );
      }),
      body: Obx(() {
        final items = _controller.managedOpenings;
        final visible = _visible(items);
        final loading = _controller.ownedLoading.value && items.isEmpty;
        return RefreshIndicator(
          edgeOffset: floatingRefreshEdgeOffset(context),
          onRefresh: _controller.loadOwnedOpenings,
          color: const Color(AppColors.primaryColor),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const FloatingSliverAppBar(title: Text('My openings')),
              PinnedSliverHeader(
                child: OpeningFiltersBar(
                  sport: _sport,
                  type: _type,
                  onSportChanged: (sport) => setState(() => _sport = sport),
                  onTypeChanged: (type) => setState(() => _type = type),
                ),
              ),
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(AppColors.primaryColor),
                      ),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          items.isEmpty
                              ? 'No openings yet.'
                              : 'No openings match these filters.',
                          style: const TextStyle(
                            color: Color(AppColors.textSecondaryColor),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = visible[index];
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                        child: ManageOpeningCard(
                          key: ValueKey(item.opening.id),
                          controller: _controller,
                          host: item.host,
                          opening: item.opening,
                        ),
                      );
                    }, childCount: visible.length),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
