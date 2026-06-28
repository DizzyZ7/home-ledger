import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';
import '../domain/household_summary.dart';

abstract class HouseholdRepository {
  Future<List<HouseholdSummary>> loadHouseholds();
  Future<HouseholdSummary> selectHousehold(String householdId);
  Future<HouseholdDetail> loadCurrentHousehold();
  Future<HouseholdMember> addMember(String email);
  Future<void> removeMember(String userId);
  Future<List<HouseholdInvite>> loadInvites();
  Future<CreatedHouseholdInvite> createInvite({int? expiresInHours});
  Future<void> revokeInvite(String inviteId);
  Future<HouseholdSummary> acceptInvite(String code);
}

class RemoteHouseholdRepository implements HouseholdRepository {
  RemoteHouseholdRepository(this._client);

  final Dio _client;

  @override
  Future<List<HouseholdSummary>> loadHouseholds() async {
    try {
      final response = await _client.get<List<dynamic>>('/households');
      final rawHouseholds = response.data ?? const [];
      return List.unmodifiable(
        rawHouseholds
            .whereType<Map<String, dynamic>>()
            .map(HouseholdSummary.fromJson)
            .toList(growable: false),
      );
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HouseholdSummary> selectHousehold(String householdId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/households/$householdId/select');
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty household response.');
      }
      return HouseholdSummary.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HouseholdDetail> loadCurrentHousehold() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/households/current');
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty household response.');
      }
      return HouseholdDetail.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HouseholdMember> addMember(String email) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/households/current/members',
        data: {'email': email},
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty household member response.');
      }
      return HouseholdMember.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<void> removeMember(String userId) async {
    try {
      await _client.delete<void>('/households/current/members/$userId');
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<List<HouseholdInvite>> loadInvites() async {
    try {
      final response = await _client.get<List<dynamic>>('/households/current/invites');
      final payload = response.data ?? const [];
      return List.unmodifiable(
        payload
            .whereType<Map<String, dynamic>>()
            .map(HouseholdInvite.fromJson)
            .toList(growable: false),
      );
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<CreatedHouseholdInvite> createInvite({int? expiresInHours}) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/households/current/invites',
        data: expiresInHours == null ? null : {'expires_in_hours': expiresInHours},
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty household invite response.');
      }
      return CreatedHouseholdInvite.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    try {
      await _client.delete<void>('/households/current/invites/$inviteId');
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HouseholdSummary> acceptInvite(String code) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/households/invites/accept',
        data: {'code': code},
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty household response.');
      }
      return HouseholdSummary.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

class MockHouseholdRepository implements HouseholdRepository {
  MockHouseholdRepository()
      : _households = [
          const HouseholdSummary(
            id: 'mock-household',
            name: 'Мой дом',
            ownerId: 'demo-user',
            role: HouseholdRole.owner,
            isActive: true,
          ),
          const HouseholdSummary(
            id: 'mock-shared-household',
            name: 'Дом с соседями',
            ownerId: 'another-demo-user',
            role: HouseholdRole.member,
            isActive: false,
          ),
        ],
        _membersByHousehold = {
          'mock-household': [
            const HouseholdMember(
              userId: 'demo-user',
              email: 'demo@homeledger.local',
              displayName: 'Демо-пользователь',
              role: HouseholdRole.owner,
            ),
            const HouseholdMember(
              userId: 'mock-member-anna',
              email: 'anna@example.com',
              displayName: 'Анна',
              role: HouseholdRole.member,
            ),
          ],
          'mock-shared-household': [
            const HouseholdMember(
              userId: 'another-demo-user',
              email: 'owner@example.com',
              displayName: 'Сосед',
              role: HouseholdRole.owner,
            ),
            const HouseholdMember(
              userId: 'demo-user',
              email: 'demo@homeledger.local',
              displayName: 'Демо-пользователь',
              role: HouseholdRole.member,
            ),
          ],
        };

  List<HouseholdSummary> _households;
  final Map<String, List<HouseholdMember>> _membersByHousehold;
  final Map<String, List<_MockHouseholdInvite>> _invitesByHousehold = {};
  var _memberSequence = 0;
  var _inviteSequence = 0;

  @override
  Future<List<HouseholdSummary>> loadHouseholds() async => List.unmodifiable(_households);

  @override
  Future<HouseholdSummary> selectHousehold(String householdId) async {
    final selected = _households.where((household) => household.id == householdId).toList(growable: false);
    if (selected.isEmpty) {
      throw const ApiException('Household was not found.');
    }
    _households = [
      for (final household in _households)
        household.copyWith(isActive: household.id == householdId),
    ];
    return _households.firstWhere((household) => household.id == householdId);
  }

  @override
  Future<HouseholdDetail> loadCurrentHousehold() async {
    final active = _activeHousehold();
    return HouseholdDetail(
      summary: active,
      members: List.unmodifiable(_membersByHousehold[active.id] ?? const []),
    );
  }

  @override
  Future<HouseholdMember> addMember(String email) async {
    final active = _activeHousehold();
    if (active.role != HouseholdRole.owner) {
      throw const ApiException('Only the household owner can manage members.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@')) {
      throw const ApiException('Enter a valid email address.');
    }
    final members = _membersByHousehold[active.id]!;
    if (members.any((member) => member.email == normalizedEmail)) {
      throw const ApiException('This user is already a household member.');
    }
    final member = HouseholdMember(
      userId: 'mock-member-${++_memberSequence}',
      email: normalizedEmail,
      displayName: normalizedEmail.split('@').first,
      role: HouseholdRole.member,
    );
    members.add(member);
    return member;
  }

  @override
  Future<void> removeMember(String userId) async {
    final active = _activeHousehold();
    if (active.role != HouseholdRole.owner) {
      throw const ApiException('Only the household owner can manage members.');
    }
    final members = _membersByHousehold[active.id]!;
    HouseholdMember? member;
    for (final candidate in members) {
      if (candidate.userId == userId) {
        member = candidate;
        break;
      }
    }
    if (member == null) {
      throw const ApiException('Household member was not found.');
    }
    if (member.role == HouseholdRole.owner) {
      throw const ApiException('The household owner cannot be removed.');
    }
    members.remove(member);
  }

  @override
  Future<List<HouseholdInvite>> loadInvites() async {
    final active = _activeHousehold();
    if (active.role != HouseholdRole.owner) {
      throw const ApiException('Only the household owner can manage invitations.');
    }
    final invites = _invitesByHousehold[active.id] ?? const <_MockHouseholdInvite>[];
    return List.unmodifiable(invites.map((invite) => invite.invite));
  }

  @override
  Future<CreatedHouseholdInvite> createInvite({int? expiresInHours}) async {
    final active = _activeHousehold();
    if (active.role != HouseholdRole.owner) {
      throw const ApiException('Only the household owner can manage invitations.');
    }
    final now = DateTime.now().toUtc();
    final id = 'mock-invite-${++_inviteSequence}';
    final code = 'HL-MOCK-${id.replaceAll('-', '').toUpperCase()}-CODE';
    final invite = HouseholdInvite(
      id: id,
      createdAt: now,
      expiresAt: now.add(Duration(hours: expiresInHours ?? 72)),
    );
    _invitesByHousehold.putIfAbsent(active.id, () => []).insert(
          0,
          _MockHouseholdInvite(invite: invite, code: code),
        );
    return CreatedHouseholdInvite(invite: invite, code: code);
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    final active = _activeHousehold();
    if (active.role != HouseholdRole.owner) {
      throw const ApiException('Only the household owner can manage invitations.');
    }
    final invites = _invitesByHousehold[active.id];
    if (invites == null) {
      throw const ApiException('Invitation was not found.');
    }
    final index = invites.indexWhere((invite) => invite.invite.id == inviteId);
    if (index == -1) {
      throw const ApiException('Invitation was not found.');
    }
    invites.removeAt(index);
  }

  @override
  Future<HouseholdSummary> acceptInvite(String code) async {
    for (final entry in _invitesByHousehold.entries) {
      for (final invite in entry.value) {
        if (invite.code.replaceAll('-', '').toUpperCase() == code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()) {
          final existing = _households.where((household) => household.id == entry.key).toList(growable: false);
          if (existing.isNotEmpty) {
            throw const ApiException('You are already a household member.');
          }
        }
      }
    }
    throw const ApiException('Invitation is invalid or expired.');
  }

  HouseholdSummary _activeHousehold() {
    return _households.firstWhere((household) => household.isActive);
  }
}

class _MockHouseholdInvite {
  const _MockHouseholdInvite({required this.invite, required this.code});

  final HouseholdInvite invite;
  final String code;
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockHouseholdRepository();
  }
  return RemoteHouseholdRepository(ref.watch(apiClientProvider));
});
