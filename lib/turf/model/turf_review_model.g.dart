// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurfReviewModel _$TurfReviewModelFromJson(Map<String, dynamic> json) =>
    TurfReviewModel(
      id: json['_id'] as String?,
      turf: const TurfConverter().fromJson(json['turf']),
      reviewedBy: const UserConverter().fromJson(json['reviewedBy']),
      rating: (json['rating'] as num).toInt(),
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      visitDate: json['visitDate'] as String?,
      isVerifiedBooking: json['isVerifiedBooking'] as bool? ?? false,
      helpfulVotes: (json['helpfulVotes'] as num?)?.toInt() ?? 0,
      notHelpfulVotes: (json['notHelpfulVotes'] as num?)?.toInt() ?? 0,
      reportedCount: (json['reportedCount'] as num?)?.toInt() ?? 0,
      isModerated: json['isModerated'] as bool? ?? false,
      moderatedAt: json['moderatedAt'] as String?,
      moderatedBy: const UserConverter().fromJson(json['moderatedBy']),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$TurfReviewModelToJson(TurfReviewModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'turf': const TurfConverter().toJson(instance.turf),
      'reviewedBy': const UserConverter().toJson(instance.reviewedBy),
      'rating': instance.rating,
      'title': instance.title,
      'comment': instance.comment,
      'images': instance.images,
      'visitDate': instance.visitDate,
      'isVerifiedBooking': instance.isVerifiedBooking,
      'helpfulVotes': instance.helpfulVotes,
      'notHelpfulVotes': instance.notHelpfulVotes,
      'reportedCount': instance.reportedCount,
      'isModerated': instance.isModerated,
      'moderatedAt': instance.moderatedAt,
      'moderatedBy': const UserConverter().toJson(instance.moderatedBy),
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

TurfReviewStats _$TurfReviewStatsFromJson(Map<String, dynamic> json) =>
    TurfReviewStats(
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
      ratingDistribution: (json['ratingDistribution'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, (e as num).toInt())),
    );

Map<String, dynamic> _$TurfReviewStatsToJson(TurfReviewStats instance) =>
    <String, dynamic>{
      'averageRating': instance.averageRating,
      'totalReviews': instance.totalReviews,
      'ratingDistribution': instance.ratingDistribution,
    };

CreateTurfReviewRequest _$CreateTurfReviewRequestFromJson(
  Map<String, dynamic> json,
) => CreateTurfReviewRequest(
  turf: json['turf'] as String,
  rating: (json['rating'] as num).toInt(),
  title: json['title'] as String?,
  comment: json['comment'] as String?,
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  visitDate: json['visitDate'] as String?,
  isVerifiedBooking: json['isVerifiedBooking'] as bool?,
);

Map<String, dynamic> _$CreateTurfReviewRequestToJson(
  CreateTurfReviewRequest instance,
) => <String, dynamic>{
  'turf': instance.turf,
  'rating': instance.rating,
  'title': instance.title,
  'comment': instance.comment,
  'images': instance.images,
  'visitDate': instance.visitDate,
  'isVerifiedBooking': instance.isVerifiedBooking,
};

UpdateTurfReviewRequest _$UpdateTurfReviewRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTurfReviewRequest(
  rating: (json['rating'] as num?)?.toInt(),
  title: json['title'] as String?,
  comment: json['comment'] as String?,
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  visitDate: json['visitDate'] as String?,
  isVerifiedBooking: json['isVerifiedBooking'] as bool?,
);

Map<String, dynamic> _$UpdateTurfReviewRequestToJson(
  UpdateTurfReviewRequest instance,
) => <String, dynamic>{
  'rating': instance.rating,
  'title': instance.title,
  'comment': instance.comment,
  'images': instance.images,
  'visitDate': instance.visitDate,
  'isVerifiedBooking': instance.isVerifiedBooking,
};

VoteTurfReviewRequest _$VoteTurfReviewRequestFromJson(
  Map<String, dynamic> json,
) => VoteTurfReviewRequest(vote: json['vote'] as String);

Map<String, dynamic> _$VoteTurfReviewRequestToJson(
  VoteTurfReviewRequest instance,
) => <String, dynamic>{'vote': instance.vote};

ReportTurfReviewRequest _$ReportTurfReviewRequestFromJson(
  Map<String, dynamic> json,
) => ReportTurfReviewRequest(reason: json['reason'] as String);

Map<String, dynamic> _$ReportTurfReviewRequestToJson(
  ReportTurfReviewRequest instance,
) => <String, dynamic>{'reason': instance.reason};

ModerateTurfReviewRequest _$ModerateTurfReviewRequestFromJson(
  Map<String, dynamic> json,
) => ModerateTurfReviewRequest(
  approve: json['approve'] as bool,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ModerateTurfReviewRequestToJson(
  ModerateTurfReviewRequest instance,
) => <String, dynamic>{'approve': instance.approve, 'notes': instance.notes};
