import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/turf_model.dart';
import '../models/common/paginated_response.dart';
import '../services/turf_service.dart';
import '../utils/exception_handler.dart';

class TurfManagementController extends GetxController {
  static TurfManagementController get instance => Get.find();

  final TurfService _turfService = TurfService();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxBool _isRefreshing = false.obs;
  final RxList<TurfModel> _myTurfs = <TurfModel>[].obs;
  final Rxn<Map<String, dynamic>> _stats = Rxn<Map<String, dynamic>>();

  // Pagination
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMoreData = true.obs;
  final RxInt _totalTurfsCount = 0.obs;
  final int _limitPerPage = 10;

  // Getters - Return observables for reactivity
  RxBool get isLoading => _isLoading;
  RxBool get isRefreshing => _isRefreshing;
  RxList<TurfModel> get myTurfs => _myTurfs;
  Rxn<Map<String, dynamic>> get stats => _stats;
  RxInt get currentPage => _currentPage;
  RxBool get hasMoreData => _hasMoreData;
  RxInt get totalTurfsCount => _totalTurfsCount;

  @override
  void onInit() {
    super.onInit();
    loadMyTurfs();
    loadMyTurfStats();
  }

  /// Load user's turfs
  Future<void> loadMyTurfs({bool showLoader = true}) async {
    try {
      if (showLoader) {
        _isLoading.value = true;
      }

      _currentPage.value = 1;
      final response = await _turfService.getMyTurfs(
        page: _currentPage.value,
        limit: _limitPerPage,
        sort: '-createdAt',
      );

      if (response != null) {
        _myTurfs.value = response.data;
        _hasMoreData.value = response.hasNextPage;
        _totalTurfsCount.value = response.totalDocuments;
      } else {
        _myTurfs.clear();
        _totalTurfsCount.value = 0;
      }
    } catch (e) {
      debugPrint('Error loading my turfs: $e');
      ExceptionHandler.showErrorToast('Failed to load your turfs');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh turfs list
  Future<void> refreshMyTurfs() async {
    try {
      _isRefreshing.value = true;
      await loadMyTurfs(showLoader: false);
      await loadMyTurfStats();
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Load more turfs (pagination)
  Future<void> loadMoreTurfs() async {
    if (!_hasMoreData.value || _isLoading.value) return;

    try {
      _currentPage.value++;
      final response = await _turfService.getMyTurfs(
        page: _currentPage.value,
        limit: _limitPerPage,
        sort: '-createdAt',
      );

      if (response != null) {
        _myTurfs.addAll(response.data);
        _hasMoreData.value = response.hasNextPage;
        _totalTurfsCount.value = response.totalDocuments;
      }
    } catch (e) {
      debugPrint('Error loading more turfs: $e');
      _currentPage.value--; // Revert page increment on error
      ExceptionHandler.showErrorToast('Failed to load more turfs');
    }
  }

  /// Load user's turf statistics
  Future<void> loadMyTurfStats() async {
    try {
      final statsData = await _turfService.getMyTurfStats();
      _stats.value = statsData;
    } catch (e) {
      debugPrint('Error loading turf stats: $e');
    }
  }

  /// Delete a turf
  Future<void> deleteTurf(TurfModel turf) async {
    if (turf.id == null) return;

    try {
      final confirmed = await _showDeleteConfirmation(turf);
      if (!confirmed) return;

      _isLoading.value = true;

      final success = await _turfService.deleteTurf(turf.id!);

      if (success) {
        _myTurfs.removeWhere((t) => t.id == turf.id);
        await loadMyTurfStats(); // Refresh stats
        ExceptionHandler.showSuccessToast('Turf deleted successfully');
      } else {
        ExceptionHandler.showErrorToast('Failed to delete turf');
      }
    } catch (e) {
      debugPrint('Error deleting turf: $e');
      ExceptionHandler.showErrorToast('Failed to delete turf');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Toggle turf availability
  Future<void> toggleTurfAvailability(TurfModel turf) async {
    if (turf.id == null) return;

    try {
      _isLoading.value = true;

      final updateRequest = UpdateTurfRequest(
        isAvailable: !(turf.isAvailable ?? false),
      );

      final updatedTurf = await _turfService.updateTurf(
        turf.id!,
        updateRequest,
      );

      if (updatedTurf != null) {
        final index = _myTurfs.indexWhere((t) => t.id == turf.id);
        if (index != -1) {
          _myTurfs[index] = updatedTurf;
        }
        ExceptionHandler.showSuccessToast(
          updatedTurf.isAvailable == true
              ? 'Turf is now available'
              : 'Turf is now unavailable',
        );
      } else {
        ExceptionHandler.showErrorToast('Failed to update turf availability');
      }
    } catch (e) {
      debugPrint('Error toggling turf availability: $e');
      ExceptionHandler.showErrorToast('Failed to update turf availability');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Navigate to edit turf screen
  void navigateToEditTurf(TurfModel turf) {
    if (turf.id != null) {
      Get.toNamed('/edit-turf', arguments: turf)?.then((result) {
        // Refresh list when returning from edit screen
        if (result == true) {
          loadMyTurfs(showLoader: false);
        }
      });
    }
  }

  /// Navigate to create turf screen
  void navigateToCreateTurf() {
    Get.toNamed('/create-turf')?.then((_) {
      // Refresh list when returning from create screen
      loadMyTurfs();
    });
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(TurfModel turf) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Delete Turf'),
            content: Text(
              'Are you sure you want to delete "${turf.displayName}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Get formatted stats for display
  String getStatsDisplay(String key) {
    final value = _stats.value?[key];
    if (value == null) return '-';
    return value.toString();
  }

  /// Check if user has any turfs
  bool get hasTurfs => _myTurfs.isNotEmpty;

  @override
  void onClose() {
    super.onClose();
  }
}
