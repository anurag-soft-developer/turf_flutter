import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/turf/booking_components.dart';
import '../../components/turf/turf_detail_scroll_content.dart';
import '../../core/components/query/query_async_body.dart';
import '../../core/config/constants.dart';
import '../../core/query/query_keys.dart';
import '../../core/query/query_retry.dart';
import '../model/turf_model.dart';
import '../turf_service.dart';
import 'turf_detail_controller.dart';

class TurfDetailScreen extends HookWidget {
  const TurfDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TurfDetailController controller = Get.find();
    final turfId = controller.turfId;

    if (turfId == null || turfId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Turf not found')),
      );
    }

    final turfQuery = useQuery<TurfModel, Object>(
      QueryKeys.turfDetail(turfId),
      (_) async {
        final turf = await TurfService().getTurfById(turfId);
        if (turf == null) throw Exception('Turf not found');
        return turf;
      },
      retry: noRetry,
    );

    useEffect(() {
      controller.syncTurf(turfQuery.data);
      return null;
    }, [turfQuery.data]);

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: QueryAsyncBody<TurfModel, Object>(
        state: turfQuery,
        onRetry: () => turfQuery.refetch(),
        data: (_) => RefreshIndicator(
          onRefresh: controller.refreshData,
          child: TurfDetailScrollContent(
            controller: controller,
            showBookingSection: true,
          ),
        ),
      ),
      floatingActionButton: BookingFloatingButton(controller: controller),
    );
  }
}
