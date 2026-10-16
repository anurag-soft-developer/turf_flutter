enum EnrollmentStatus {
  pending,
  accepted,
  rejected;

  String get apiValue => name;

  static EnrollmentStatus? fromApi(String? raw) {
    for (final value in EnrollmentStatus.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

class EnrollmentModel {
  const EnrollmentModel({
    this.id,
    required this.openingId,
    required this.subjectType,
    required this.status,
    this.userId,
    this.userName,
    this.userAvatar,
    this.teamId,
    this.teamName,
    this.teamLogo,
    this.tournamentId,
    this.title = '',
    this.sportType,
    this.hostName = '',
    this.hostImage,
    this.hostPlace,
  });

  final String? id;
  final String openingId;
  final String subjectType;
  final EnrollmentStatus status;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String? teamId;
  final String? teamName;
  final String? teamLogo;
  final String? tournamentId;
  final String title;
  final String? sportType;
  final String hostName;
  final String? hostImage;
  final String? hostPlace;

  bool get isTournament => subjectType == 'tournament';

  /// Team being joined, or the tournament being entered.
  String get hostId => isTournament ? (tournamentId ?? '') : (teamId ?? '');

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    final status = EnrollmentStatus.fromApi(json['status'] as String?);
    if (status == null) {
      throw FormatException('Unknown enrollment payload');
    }
    return EnrollmentModel(
      id: json['_id'] as String?,
      openingId: json['openingId'] as String? ?? '',
      subjectType: json['subjectType'] as String? ?? '',
      status: status,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      teamLogo: json['teamLogo'] as String?,
      tournamentId: json['tournamentId'] as String?,
      title: json['title'] as String? ?? '',
      sportType: json['sportType'] as String?,
      hostName: json['hostName'] as String? ?? '',
      hostImage: json['hostImage'] as String?,
      hostPlace: json['hostPlace'] as String?,
    );
  }
}

class EnrollmentListQuery {
  const EnrollmentListQuery({
    this.status,
    this.page = 1,
    this.limit = 20,
    this.teamId,
  });

  final EnrollmentStatus? status;
  final int page;
  final int limit;
  final String? teamId;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.clamp(1, 50).toString(),
    };
    if (status != null) params['status'] = status!.apiValue;
    final team = teamId?.trim();
    if (team != null && team.isNotEmpty) params['teamId'] = team;
    return params;
  }
}
