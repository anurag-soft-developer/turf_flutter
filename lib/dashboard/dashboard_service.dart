import '../core/config/api_constants.dart';
import '../core/models/location_model.dart';
import '../core/services/api_service.dart';
import 'model/player_dashboard_model.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiService _apiService = ApiService();

  /// Aggregated player home payload: turfs section + nearby open-for-match count.
  Future<PlayerDashboardModel?> getPlayerDashboard({
    LocationModel? location,
    double? nearbyRadiusKm,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (location != null) {
      queryParams.addAll(
        nearbyLocationQueryParameters(
          nearbyLat: location.latitude,
          nearbyLng: location.longitude,
          nearbyRadiusKm: nearbyRadiusKm,
        ),
      );
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.dashboard.player,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    if (response == null) return null;
    return PlayerDashboardModel.fromJson(response);
  }
}
