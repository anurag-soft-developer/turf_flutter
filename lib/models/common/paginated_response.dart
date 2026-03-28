import 'package:json_annotation/json_annotation.dart';

part 'paginated_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  @JsonKey(name: 'data')
  final List<T> data;

  @JsonKey(name: 'totalDocuments')
  final int totalDocuments;

  @JsonKey(name: 'page')
  final int page;

  @JsonKey(name: 'limit')
  final int limit;

  @JsonKey(name: 'totalPages')
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.totalDocuments,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);

  // Helper getters
  bool get hasData => data.isNotEmpty;
  bool get isEmpty => data.isEmpty;
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
  int get itemsOnCurrentPage => data.length;

  // Helper method to check if it's the first page
  bool get isFirstPage => page == 1;

  // Helper method to check if it's the last page
  bool get isLastPage => page == totalPages;

  PaginatedResponse<T> copyWith({
    List<T>? data,
    int? totalDocuments,
    int? page,
    int? limit,
    int? totalPages,
  }) {
    return PaginatedResponse<T>(
      data: data ?? this.data,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  String toString() {
    return 'PaginatedResponse<$T>(page: $page/$totalPages, items: ${data.length}/$totalDocuments)';
  }
}

// Helper class for empty paginated responses
class EmptyPaginatedResponse<T> extends PaginatedResponse<T> {
  EmptyPaginatedResponse()
    : super(data: [], totalDocuments: 0, page: 1, limit: 10, totalPages: 0);
}
