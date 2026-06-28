import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/household_summary.dart';

abstract class HouseholdRepository {
  Future<List<HouseholdSummary>> loadHouseholds();
  Future<HouseholdSummary> selectHousehold(String householdId);
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
        ];

  List<HouseholdSummary> _households;

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
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockHouseholdRepository();
  }
  return RemoteHouseholdRepository(ref.watch(apiClientProvider));
});
