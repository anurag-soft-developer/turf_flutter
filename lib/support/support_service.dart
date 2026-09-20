import '../core/config/api_constants.dart';
import '../core/models/paginated_response.dart';
import '../core/services/api_service.dart';
import 'model/support_query_model.dart';

class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;
  SupportService._internal();

  final ApiService _api = ApiService();

  Future<SupportQueryModel?> createQuery(CreateSupportQueryPayload payload) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.support.queries,
      data: payload.toJson(),
    );
    if (response == null) return null;
    return SupportQueryModel.fromJson(response);
  }

  Future<PaginatedResponse<SupportQueryModel>?> listMine({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.support.mine,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
    if (response == null) {
      return EmptyPaginatedResponse<SupportQueryModel>();
    }
    return PaginatedResponse.fromJson(
      response,
      (json) => SupportQueryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SupportQueryModel?> getById(String id) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiConstants.support.byId(id),
    );
    if (response == null) return null;
    return SupportQueryModel.fromJson(response);
  }

  Future<SupportQueryModel?> addReply(String id, String body) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.support.replies(id),
      data: {'body': body},
    );
    if (response == null) return null;
    return SupportQueryModel.fromJson(response);
  }
}
