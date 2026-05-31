import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../settings/settings_controller.dart';
import '../../../turf/model/turf_model.dart';
import '../../../turf/turf_service.dart';

class ProposeTurfSheetController extends GetxController {
  ProposeTurfSheetController({this.sportTypes});

  final List<String>? sportTypes;

  final TurfService _turfService = TurfService();
  final SettingsController _settings = Get.find<SettingsController>();

  final TextEditingController searchController = TextEditingController();
  final RxList<TurfModel> turfs = <TurfModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString selectedTurfId = RxnString();

  final RxString searchQuery = ''.obs;

  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchTextChanged);
    searchTurfs();
  }

  void _onSearchTextChanged() {
    searchQuery.value = searchController.text;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), searchTurfs);
  }

  Future<void> searchTurfs() async {
    isLoading.value = true;
    try {
      final query = searchController.text.trim();
      final response = await _turfService.searchTurfs(
        globalSearchText: query.isNotEmpty ? query : null,
        sportTypes: sportTypes,
        location: _settings.selectedCityLocation.value,
        limit: 20,
        sort: 'distance:asc',
      );
      turfs.assignAll(response?.data ?? const []);
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchTurfs();
  }

  void selectTurf(String? turfId) {
    if (turfId == null || turfId.isEmpty) return;
    selectedTurfId.value = turfId;
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_onSearchTextChanged);
    searchController.dispose();
    super.onClose();
  }
}
