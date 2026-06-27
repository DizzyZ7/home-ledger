class UserSession {
  const UserSession({required this.userId, required this.email, required this.displayName});

  final String userId;
  final String email;
  final String displayName;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
    );
  }

  static const demo = UserSession(
    userId: 'demo-user',
    email: 'demo@homeledger.local',
    displayName: 'Demo owner',
  );
}
