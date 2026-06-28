import 'package:flutter/foundation.dart';

@immutable
class HouseholdSummary {
  const HouseholdSummary({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String name;
  final String ownerId;
  final HouseholdRole role;
  final bool isActive;

  factory HouseholdSummary.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'owner' => HouseholdRole.owner,
      'member' => HouseholdRole.member,
      _ => throw const FormatException('Unknown household role.'),
    };

    return HouseholdSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      role: role,
      isActive: json['is_active'] as bool,
    );
  }

  HouseholdSummary copyWith({bool? isActive}) {
    return HouseholdSummary(
      id: id,
      name: name,
      ownerId: ownerId,
      role: role,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum HouseholdRole { owner, member }
