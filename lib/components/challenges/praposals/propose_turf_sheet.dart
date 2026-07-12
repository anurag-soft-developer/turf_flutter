import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/query/query_keys.dart';
import '../../../settings/settings_controller.dart';
import '../../../turf/model/turf_model.dart';
import '../../../turf/turf_service.dart';

Duration? _noRetry(int count, Object error) => null;

class ProposeTurfSheet extends HookWidget {
  final List<String>? sportTypes;

  const ProposeTurfSheet({super.key, this.sportTypes});

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');
    final selectedTurfId = useState<String?>(null);
    final settings = Get.find<SettingsController>();

    useEffect(() {
      void listener() {
        searchText.value = searchController.text;
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 400), () {
        debouncedSearch.value = searchText.value.trim();
      });
      return timer.cancel;
    }, [searchText.value]);

    final city = settings.selectedCityLocation.value;
    final cityKey = city == null ? '' : '${city.latitude},${city.longitude}';
    final queryKey = QueryKeys.turfSearch(
      search: debouncedSearch.value,
      sportTypes: sportTypes,
      city: cityKey,
    );

    final turfsQuery = useQuery<List<TurfModel>, Object>(
      queryKey,
      (_) async {
        final response = await TurfService().searchTurfs(
          globalSearchText:
              debouncedSearch.value.isNotEmpty ? debouncedSearch.value : null,
          sportTypes: sportTypes,
          location: settings.selectedCityLocation.value,
          limit: 20,
          sort: 'distance:asc',
        );
        return response?.data ?? const <TurfModel>[];
      },
      retry: _noRetry,
    );

    final turfs = turfsQuery.data ?? const <TurfModel>[];
    final isLoading = turfsQuery.isLoading ||
        (turfsQuery.isFetching && turfs.isEmpty);

    return Material(
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
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: Color(AppColors.textColor)),
                  decoration: InputDecoration(
                    hintText: 'Search turf by name or address',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(AppColors.backgroundColor),
                    suffixIcon: searchText.value.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              searchText.value = '';
                              debouncedSearch.value = '';
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildTurfList(
                    turfs: turfs,
                    isLoading: isLoading,
                    isFetching: turfsQuery.isFetching,
                    selectedTurfId: selectedTurfId.value,
                    onSelect: (id) => selectedTurfId.value = id,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedTurfId.value == null || isLoading
                        ? null
                        : () => Navigator.of(context)
                            .pop(selectedTurfId.value),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurfList({
    required List<TurfModel> turfs,
    required bool isLoading,
    required bool isFetching,
    required String? selectedTurfId,
    required ValueChanged<String?> onSelect,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (turfs.isEmpty) {
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
          groupValue: selectedTurfId,
          onChanged: onSelect,
          child: ListView.separated(
            itemCount: turfs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final turf = turfs[index];
              return _TurfTile(
                turf: turf,
                onTap: () => onSelect(turf.id),
              );
            },
          ),
        ),
        if (isFetching)
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
