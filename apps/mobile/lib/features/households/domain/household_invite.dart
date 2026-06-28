class HouseholdInvite {
  const HouseholdInvite({
    required this.id,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final DateTime expiresAt;
  final DateTime createdAt;

  factory HouseholdInvite.fromJson(Map<String, dynamic> json) {
    return HouseholdInvite(
      id: json['id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CreatedHouseholdInvite {
  const CreatedHouseholdInvite({
    required this.invite,
    required this.code,
  });

  final HouseholdInvite invite;
  final String code;

  factory CreatedHouseholdInvite.fromJson(Map<String, dynamic> json) {
    return CreatedHouseholdInvite(
      invite: HouseholdInvite(
        id: json['id'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      ),
      code: json['code'] as String,
    );
  }
}
