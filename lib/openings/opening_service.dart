import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'model/enrollment_model.dart';
import 'model/opening_model.dart';

class OpeningService {
  static final OpeningService _instance = OpeningService._internal();
  factory OpeningService() => _instance;
  OpeningService._internal();

  final ApiService _apiService = ApiService();

  Future<PaginatedResponse<OpeningModel>?> findMany(
    OpeningFilterQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.openings.base,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) {
      return EmptyPaginatedResponse<OpeningModel>();
    }
    return PaginatedResponse.fromJson(response, (json) {
      return OpeningModel.fromJson(json as Map<String, dynamic>);
    });
  }

  /// Open or on-hold requirement for a team or tournament, if one exists.
  Future<OpeningModel?> findByTarget({
    required OpeningType type,
    required String targetId,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.openings.byTarget,
      queryParameters: {
        'type': type.apiValue,
        if (type == OpeningType.team) 'teamId': targetId,
        if (type == OpeningType.tournament) 'tournamentId': targetId,
      },
    );
    final opening = response?['opening'];
    if (opening is! Map) return null;
    return OpeningModel.fromJson(Map<String, dynamic>.from(opening));
  }

  Future<OpeningModel?> create({
    required OpeningType type,
    required String targetId,
    required String title,
    int maxPendingJoinRequests = 50,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.openings.base,
      data: {
        'type': type.apiValue,
        if (type == OpeningType.team) 'teamId': targetId,
        if (type == OpeningType.tournament) 'tournamentId': targetId,
        'title': title,
        'maxPendingJoinRequests': maxPendingJoinRequests,
      },
    );
    if (response == null) return null;
    return OpeningModel.fromJson(response);
  }

  Future<OpeningModel?> update(
    String id, {
    String? title,
    OpeningStatus? status,
    int? maxPendingJoinRequests,
  }) async {
    final data = <String, dynamic>{
      if (title != null) 'title': title,
      if (status != null) 'status': status.apiValue,
      if (maxPendingJoinRequests != null)
        'maxPendingJoinRequests': maxPendingJoinRequests,
    };
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiConstants.openings.byId(id),
      data: data,
    );
    if (response == null) return null;
    return OpeningModel.fromJson(response);
  }

  /// Teams and tournaments the user can post for, each with its live opening.
  Future<List<OwnedOpening>?> mine() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.openings.mine,
    );
    if (response == null) return null;
    final raw = response['hosts'];
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is! Map) return null;
          return OwnedOpening.fromJson(Map<String, dynamic>.from(item));
        })
        .whereType<OwnedOpening>()
        .toList();
  }

  Future<EnrollmentModel?> enroll(String openingId, {String? teamId}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.openings.enroll(openingId),
      data: {if (teamId != null) 'teamId': teamId},
    );
    if (response == null) return null;
    return EnrollmentModel.fromJson(response);
  }

  Future<bool> withdraw(String openingId, {String? teamId}) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.openings.enroll(openingId),
      queryParameters: EnrollmentListQuery(teamId: teamId).toQueryParameters(),
    );
    return response != null;
  }

  Future<PaginatedResponse<EnrollmentModel>?> myEnrollments(
    EnrollmentListQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.enrollments.mine,
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) return EmptyPaginatedResponse<EnrollmentModel>();
    return PaginatedResponse.fromJson(response, (json) {
      return EnrollmentModel.fromJson(json as Map<String, dynamic>);
    });
  }

  Future<PaginatedResponse<EnrollmentModel>?> enrollmentsForOpening(
    String openingId,
    EnrollmentListQuery query,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.openings.enrollments(openingId),
      queryParameters: query.toQueryParameters(),
    );
    if (response == null) return EmptyPaginatedResponse<EnrollmentModel>();
    return PaginatedResponse.fromJson(response, (json) {
      return EnrollmentModel.fromJson(json as Map<String, dynamic>);
    });
  }

  Future<EnrollmentModel?> accept(String openingId, String enrollmentId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.openings.acceptEnrollment(openingId, enrollmentId),
    );
    if (response == null) return null;
    return EnrollmentModel.fromJson(response);
  }

  Future<EnrollmentModel?> reject(String openingId, String enrollmentId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.openings.rejectEnrollment(openingId, enrollmentId),
    );
    if (response == null) return null;
    return EnrollmentModel.fromJson(response);
  }
}
