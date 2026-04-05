import 'package:flutter_application_1/team/model/team_model.dart'
    show TeamSportType;
import 'package:json_annotation/json_annotation.dart';

import '../location_model.dart';

part 'team_member_field_instance.g.dart';

/// Populated `team` subset from backend [teamPopulateSelectFields].
@JsonSerializable(explicitToJson: true)
class TeamMemberFieldInstance {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  @JsonKey(defaultValue: '')
  final String logo;
  final LocationModel? location;
  final TeamSportType sportType;

  TeamMemberFieldInstance({
    this.id,
    required this.name,
    this.logo = '',
    this.location,
    required this.sportType,
  });

  factory TeamMemberFieldInstance.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberFieldInstanceFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMemberFieldInstanceToJson(this);
}
