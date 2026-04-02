import 'package:json_annotation/json_annotation.dart';

import '../../core/models/user_field_converters.dart';
import '../../core/models/turf_field_instance.dart';
import '../../core/models/user_field_instance.dart';
import 'turf_field_converter.dart';

part 'turf_review_model.g.dart';

@JsonSerializable()
class TurfReviewModel {
  @JsonKey(name: '_id')
  final String? id;

  @TurfConverter()
  final dynamic turf;

  @JsonKey(name: 'reviewedBy')
  @UserConverter()
  final dynamic reviewedBy;

  final int rating;

  final String? title;

  final String? comment;

  final List<String>? images;

  @JsonKey(name: 'visitDate')
  final String? visitDate;

  @JsonKey(name: 'isVerifiedBooking', defaultValue: false)
  final bool isVerifiedBooking;

  @JsonKey(name: 'helpfulVotes', defaultValue: 0)
  final int helpfulVotes;

  @JsonKey(name: 'notHelpfulVotes', defaultValue: 0)
  final int notHelpfulVotes;

  @JsonKey(name: 'reportedCount', defaultValue: 0)
  final int reportedCount;

  @JsonKey(name: 'isModerated', defaultValue: false)
  final bool isModerated;

  @JsonKey(name: 'moderatedAt')
  final String? moderatedAt;

  @JsonKey(name: 'moderatedBy')
  @UserConverter()
  final dynamic moderatedBy;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  TurfReviewModel({
    this.id,
    this.turf,
    this.reviewedBy,
    required this.rating,
    this.title,
    this.comment,
    this.images,
    this.visitDate,
    this.isVerifiedBooking = false,
    this.helpfulVotes = 0,
    this.notHelpfulVotes = 0,
    this.reportedCount = 0,
    this.isModerated = false,
    this.moderatedAt,
    this.moderatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory TurfReviewModel.fromJson(Map<String, dynamic> json) =>
      _$TurfReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$TurfReviewModelToJson(this);

  TurfFieldInstance? _turfHelper;
  TurfFieldInstance get turfHelper {
    _turfHelper ??= TurfFieldInstance(turf);
    return _turfHelper!;
  }

  UserFieldInstance? _reviewedByHelper;
  UserFieldInstance get reviewedByHelper {
    _reviewedByHelper ??= UserFieldInstance(reviewedBy);
    return _reviewedByHelper!;
  }

  UserFieldInstance? _moderatedByHelper;
  UserFieldInstance get moderatedByHelper {
    _moderatedByHelper ??= UserFieldInstance(moderatedBy);
    return _moderatedByHelper!;
  }

  DateTime? get visitDateParsed {
    if (visitDate == null) return null;
    try {
      return DateTime.parse(visitDate!);
    } catch (_) {
      return null;
    }
  }
}

@JsonSerializable()
class TurfReviewStats {
  @JsonKey(name: 'averageRating')
  final double? averageRating;

  @JsonKey(name: 'totalReviews')
  final int? totalReviews;

  /// Count per star level when the API returns a map (e.g. `"5": 12`).
  @JsonKey(name: 'ratingDistribution')
  final Map<String, int>? ratingDistribution;

  TurfReviewStats({
    this.averageRating,
    this.totalReviews,
    this.ratingDistribution,
  });

  factory TurfReviewStats.fromJson(Map<String, dynamic> json) =>
      _$TurfReviewStatsFromJson(json);

  Map<String, dynamic> toJson() => _$TurfReviewStatsToJson(this);
}

@JsonSerializable()
class CreateTurfReviewRequest {
  final String turf;
  final int rating;
  final String? title;
  final String? comment;
  final List<String>? images;
  final String? visitDate;
  @JsonKey(name: 'isVerifiedBooking')
  final bool? isVerifiedBooking;

  CreateTurfReviewRequest({
    required this.turf,
    required this.rating,
    this.title,
    this.comment,
    this.images,
    this.visitDate,
    this.isVerifiedBooking,
  });

  factory CreateTurfReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTurfReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTurfReviewRequestToJson(this);
}

@JsonSerializable()
class UpdateTurfReviewRequest {
  final int? rating;
  final String? title;
  final String? comment;
  final List<String>? images;
  final String? visitDate;
  @JsonKey(name: 'isVerifiedBooking')
  final bool? isVerifiedBooking;

  UpdateTurfReviewRequest({
    this.rating,
    this.title,
    this.comment,
    this.images,
    this.visitDate,
    this.isVerifiedBooking,
  });

  factory UpdateTurfReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTurfReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTurfReviewRequestToJson(this);
}

/// Body for `POST /turf-reviews/:id/vote`. Align keys with your Nest `VoteReviewDto`.
@JsonSerializable()
class VoteTurfReviewRequest {
  /// Expected values: `helpful` | `notHelpful` (match backend zod enum if different).
  final String vote;

  VoteTurfReviewRequest({required this.vote});

  factory VoteTurfReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$VoteTurfReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoteTurfReviewRequestToJson(this);
}

@JsonSerializable()
class ReportTurfReviewRequest {
  final String reason;

  ReportTurfReviewRequest({required this.reason});

  factory ReportTurfReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportTurfReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReportTurfReviewRequestToJson(this);
}

@JsonSerializable()
class ModerateTurfReviewRequest {
  final bool approve;
  final String? notes;

  ModerateTurfReviewRequest({required this.approve, this.notes});

  factory ModerateTurfReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$ModerateTurfReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ModerateTurfReviewRequestToJson(this);
}

/// Query string map for list endpoints (`GET /turf-reviews`, `my-reviews`, `turf/:id`).
class TurfReviewListQuery {
  final String? turf;
  final String? reviewedBy;
  final int? rating;
  final bool? isModerated;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const TurfReviewListQuery({
    this.turf,
    this.reviewedBy,
    this.rating,
    this.isModerated,
    this.page = 1,
    this.limit = 10,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  Map<String, dynamic> toQueryParameters() {
    final m = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
    if (turf != null) m['turf'] = turf;
    if (reviewedBy != null) m['reviewedBy'] = reviewedBy;
    if (rating != null) m['rating'] = rating.toString();
    if (isModerated != null) m['isModerated'] = isModerated.toString();
    return m;
  }
}
