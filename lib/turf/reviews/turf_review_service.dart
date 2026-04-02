import '../../core/config/api_constants.dart';
import '../../core/models/paginated_response.dart';
import '../model/turf_review_model.dart';
import '../../core/services/api_service.dart';

class TurfReviewService {
  static final TurfReviewService _instance = TurfReviewService._internal();
  factory TurfReviewService() => _instance;
  TurfReviewService._internal();

  final ApiService _apiService = ApiService();

  Future<TurfReviewModel?> createReview(CreateTurfReviewRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfReview.base,
      data: request.toJson(),
    );
    if (response == null) return null;
    return TurfReviewModel.fromJson(response);
  }

  Future<PaginatedResponse<TurfReviewModel>?> findAll(
    TurfReviewListQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.turfReview.base,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) return null;
    return PaginatedResponse.fromJson(
      response,
      (json) => TurfReviewModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<TurfReviewModel>?> findMyReviews(
    TurfReviewListQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.turfReview.myReviews,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) return null;
    return PaginatedResponse.fromJson(
      response,
      (json) => TurfReviewModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<TurfReviewModel>?> findTurfReviews(
    String turfId,
    TurfReviewListQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.turfReview.turfReviews(turfId),
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) return null;
    return PaginatedResponse.fromJson(
      response,
      (json) => TurfReviewModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<TurfReviewStats?> getTurfReviewStats(String turfId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.turfReview.turfReviewStats(turfId),
    );
    if (response == null) return null;
    return TurfReviewStats.fromJson(response);
  }

  Future<TurfReviewModel?> findById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.turfReview.byId(id),
    );
    if (response == null) return null;
    return TurfReviewModel.fromJson(response);
  }

  Future<TurfReviewModel?> updateReview(
    String id,
    UpdateTurfReviewRequest request,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.turfReview.byId(id),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TurfReviewModel.fromJson(response);
  }

  Future<TurfReviewModel?> voteReview(
    String id,
    VoteTurfReviewRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfReview.vote(id),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TurfReviewModel.fromJson(response);
  }

  Future<TurfReviewModel?> reportReview(
    String id,
    ReportTurfReviewRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfReview.report(id),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TurfReviewModel.fromJson(response);
  }

  Future<TurfReviewModel?> moderateReview(
    String id,
    ModerateTurfReviewRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.turfReview.moderate(id),
      data: request.toJson(),
    );
    if (response == null) return null;
    return TurfReviewModel.fromJson(response);
  }

  Future<bool> deleteReview(String id) async {
    return _apiService.deleteResource(ApiConstants.turfReview.byId(id));
  }
}
