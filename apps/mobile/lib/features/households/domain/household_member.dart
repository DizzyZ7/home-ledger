import 'package:flutter/foundation.dart';

import 'household_summary.dart';

@immutable
class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String email;
  final String displayName;
  final HouseholdRole role;

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'owner' => HouseholdRole.owner,
      'member' => HouseholdRole.member,
      _ => throw const FormatException('Unknown household role.'),
    };
    return HouseholdMember(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      role: role,
    );
  }
}

@immutable
class HouseholdDetail {
  const HouseholdDetail({
    required this.summary,
    required this.members,
  });

  final HouseholdSummary summary;
  final List<HouseholdMember> members;

  factory HouseholdDetail.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    return HouseholdDetail(
      summary: HouseholdSummary.fromJson(json),
      members: List.unmodifiable(
        rawMembers.whereType<Map<String, dynamic>>().map(HouseholdMember.fromJson),
      ),
    );
  }
}
