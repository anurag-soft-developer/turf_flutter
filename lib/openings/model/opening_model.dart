import 'enrollment_model.dart';

enum OpeningType {
  team,
  tournament;

  String get apiValue => name;

  static OpeningType? fromApi(String? raw) {
    for (final value in OpeningType.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

enum OpeningStatus {
  open,
  onHold,
  closed;

  String get apiValue => name;

  static OpeningStatus? fromApi(String? raw) {
    for (final value in OpeningStatus.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

enum OpeningJoinMode {
  open,
  approval;

  String get apiValue => name;

  static OpeningJoinMode? fromApi(String? raw) {
    for (final value in OpeningJoinMode.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

class OpeningModel {
  const OpeningModel({
    this.id,
    required this.type,
    this.teamId,
    this.tournamentId,
    required this.postedBy,
    required this.title,
    this.sportType,
    required this.status,
    this.joinMode = OpeningJoinMode.approval,
    this.maxPendingJoinRequests = 50,
    required this.hostName,
    this.hostImage,
    this.hostPlace,
    this.myStatus,
  });

  final String? id;
  final OpeningType type;
  final String? teamId;
  final String? tournamentId;
  final String postedBy;
  final String title;
  final String? sportType;
  final OpeningStatus status;
  final OpeningJoinMode joinMode;
  final int maxPendingJoinRequests;
  final String hostName;
  final String? hostImage;
  final String? hostPlace;
  final EnrollmentStatus? myStatus;

  String get hostId =>
      type == OpeningType.team ? (teamId ?? '') : (tournamentId ?? '');

  factory OpeningModel.fromJson(Map<String, dynamic> json) {
    final type = OpeningType.fromApi(json['type'] as String?);
    final status = OpeningStatus.fromApi(json['status'] as String?);
    if (type == null || status == null) {
      throw FormatException('Unknown opening payload');
    }
    return OpeningModel(
      id: json['_id'] as String?,
      type: type,
      teamId: json['teamId'] as String?,
      tournamentId: json['tournamentId'] as String?,
      postedBy: json['postedBy'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sportType: json['sportType'] as String?,
      status: status,
      joinMode:
          OpeningJoinMode.fromApi(json['joinMode'] as String?) ??
          OpeningJoinMode.approval,
      maxPendingJoinRequests:
          (json['maxPendingJoinRequests'] as num?)?.toInt() ?? 50,
      hostName: json['hostName'] as String? ?? '',
      hostImage: json['hostImage'] as String?,
      hostPlace: json['hostPlace'] as String?,
      myStatus: EnrollmentStatus.fromApi(json['myStatus'] as String?),
    );
  }
}

/// A team or tournament the signed-in user can post for, plus its live openings.
class OwnedOpening {
  const OwnedOpening({
    required this.type,
    required this.id,
    required this.name,
    this.sportType,
    required this.discoverable,
    this.openings = const [],
  });

  final OpeningType type;
  final String id;
  final String name;
  final String? sportType;
  final bool discoverable;
  final List<OpeningModel> openings;

  bool get isTeam => type == OpeningType.team;

  OwnedOpening copyWith({List<OpeningModel>? openings}) {
    return OwnedOpening(
      type: type,
      id: id,
      name: name,
      sportType: sportType,
      discoverable: discoverable,
      openings: openings ?? this.openings,
    );
  }

  static OwnedOpening? fromJson(Map<String, dynamic> json) {
    final type = OpeningType.fromApi(json['type'] as String?);
    final id = json['_id'] as String?;
    final name = json['name'] as String?;
    if (type == null || id == null || id.isEmpty || name == null) return null;
    final rawOpenings = json['openings'];
    final openings = <OpeningModel>[];
    if (rawOpenings is List) {
      for (final item in rawOpenings) {
        if (item is Map) {
          openings.add(OpeningModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return OwnedOpening(
      type: type,
      id: id,
      name: name,
      sportType: json['sportType'] as String?,
      discoverable: json['discoverable'] == true,
      openings: openings,
    );
  }
}

/// One live opening shown on the manage list.
class ManagedOpening {
  const ManagedOpening({required this.host, required this.opening});

  final OwnedOpening host;
  final OpeningModel opening;
}

class OpeningFilterQuery {
  const OpeningFilterQuery({
    this.type,
    this.sportType,
    this.status = OpeningStatus.open,
    this.page = 1,
    this.limit = 20,
  });

  final OpeningType? type;
  final String? sportType;
  final OpeningStatus status;
  final int page;
  final int limit;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'status': status.apiValue,
      'page': page.toString(),
      'limit': limit.clamp(1, 50).toString(),
    };
    if (type != null) params['type'] = type!.apiValue;
    final sport = sportType?.trim();
    if (sport != null && sport.isNotEmpty) params['sportType'] = sport;
    return params;
  }
}
