import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/household_member.dart';
import '../domain/household_summary.dart';

abstract class HouseholdRepository {
  Future<List<HouseholdSummary>> loadHouseholds();
  Future<HouseholdSummary> selectHousehold(String householdId);
  Future<HouseholdDetail> loadCurrentHousehold();
  Future<HouseholdMember> addMember(String email);
  Future<void> removeMember(String userId);
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
  var _memberSequence = 0;

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
    final member = members.where((candidate) => candidate.userId == userId).firstOrNull;
    if (member == null) {
      throw const ApiException('Household member was not found.');
    }
    if (member.role == HouseholdRole.owner) {
      throw const ApiException('The household owner cannot be removed.');
    }
    members.remove(member);
  }

  HouseholdSummary _activeHousehold() {
    return _households.firstWhere((household) => household.isActive);
  }
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockHouseholdRepository();
  }
  return RemoteHouseholdRepository(ref.watch(apiClientProvider));
});
