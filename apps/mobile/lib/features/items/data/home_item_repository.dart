import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/home_item.dart';
import '../domain/warranty_state.dart';
import 'home_item_cache.dart';

abstract class HomeItemRepository {
  Future<List<HomeItem>> loadItems();
  Future<List<HomeItem>> loadArchivedItems();
  Future<List<HomeItem>> loadWarrantyItems({
    required WarrantyState state,
    int windowDays = 45,
  });
  Future<HomeItem> createItem(HomeItem item);
  Future<HomeItem> updateItem(HomeItem item);
  Future<void> archiveItem(String itemId);
  Future<HomeItem> restoreItem(String itemId);
}

List<HomeItem> filterWarrantyItems(
  Iterable<HomeItem> items, {
  required WarrantyState state,
  int windowDays = 45,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final windowEnd = today.add(Duration(days: windowDays));

  final filtered = items.where((item) {
    final warranty = item.warrantyExpiresAt;
    return switch (state) {
      WarrantyState.expired => warranty != null && warranty.isBefore(today),
      WarrantyState.expiring =>
        warranty != null && !warranty.isBefore(today) && !warranty.isAfter(windowEnd),
      WarrantyState.valid => warranty != null && warranty.isAfter(windowEnd),
      WarrantyState.none => warranty == null,
    };
  }).toList(growable: false);

  if (state != WarrantyState.none) {
    filtered.sort((left, right) => left.warrantyExpiresAt!.compareTo(right.warrantyExpiresAt!));
  }
  return List.unmodifiable(filtered);
}

class RemoteHomeItemRepository implements HomeItemRepository {
  RemoteHomeItemRepository(this._client, this._cache);

  final Dio _client;
  final HomeItemCache _cache;

  @override
  Future<List<HomeItem>> loadItems() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/items');
      final items = _itemsFromPayload(response.data);
      await _cache.write(items);
      return items;
    } on DioException catch (exception) {
      final cached = await _cache.read();
      if (cached.isNotEmpty) {
        return cached;
      }
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<List<HomeItem>> loadArchivedItems() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/items',
        queryParameters: const {'archived': true},
      );
      return _itemsFromPayload(response.data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<List<HomeItem>> loadWarrantyItems({
    required WarrantyState state,
    int windowDays = 45,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/items',
        queryParameters: {
          'warranty_state': state.apiValue,
          'warranty_window_days': windowDays,
          'page_size': 100,
        },
      );
      return _itemsFromPayload(response.data);
    } on DioException catch (exception) {
      final cached = await _cache.read();
      if (cached.isNotEmpty) {
        return filterWarrantyItems(cached, state: state, windowDays: windowDays);
      }
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HomeItem> createItem(HomeItem item) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/items',
        data: item.toCreatePayload(),
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty item response.');
      }
      final created = HomeItem.fromJson(payload);
      final cachedItems = await _cache.read();
      await _cache.write([
        created,
        ...cachedItems.where((cachedItem) => cachedItem.id != created.id),
      ]);
      return created;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HomeItem> updateItem(HomeItem item) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/items/${item.id}',
        data: item.toCreatePayload(),
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty item response.');
      }
      final updated = HomeItem.fromJson(payload);
      final cachedItems = await _cache.read();
      await _cache.write([
        for (final cachedItem in cachedItems)
          if (cachedItem.id == updated.id) updated else cachedItem,
      ]);
      return updated;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<void> archiveItem(String itemId) async {
    try {
      await _client.delete<void>('/items/$itemId');
      final cachedItems = await _cache.read();
      await _cache.write(cachedItems.where((item) => item.id != itemId).toList());
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<HomeItem> restoreItem(String itemId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/items/$itemId/restore');
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty item response.');
      }
      final restored = HomeItem.fromJson(payload);
      final cachedItems = await _cache.read();
      await _cache.write([
        restored,
        ...cachedItems.where((item) => item.id != restored.id),
      ]);
      return restored;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  List<HomeItem> _itemsFromPayload(Map<String, dynamic>? payload) {
    final itemsRaw = payload?['items'] as List<dynamic>? ?? const [];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(HomeItem.fromJson)
        .toList(growable: false);
  }
}

class MockHomeItemRepository implements HomeItemRepository {
  MockHomeItemRepository()
      : _items = [
          HomeItem(
            id: 'demo-router',
            name: 'Wi-Fi router',
            category: 'electronics',
            location: 'Living room',
            warrantyExpiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
          HomeItem(
            id: 'demo-washer',
            name: 'Washing machine',
            category: 'appliance',
            location: 'Bathroom',
            warrantyExpiresAt: DateTime.now().add(const Duration(days: 310)),
          ),
        ];

  final List<HomeItem> _items;
  final List<HomeItem> _archivedItems = [];

  @override
  Future<List<HomeItem>> loadItems() async => List.unmodifiable(_items);

  @override
  Future<List<HomeItem>> loadArchivedItems() async => List.unmodifiable(_archivedItems);

  @override
  Future<List<HomeItem>> loadWarrantyItems({
    required WarrantyState state,
    int windowDays = 45,
  }) async {
    return filterWarrantyItems(_items, state: state, windowDays: windowDays);
  }

  @override
  Future<HomeItem> createItem(HomeItem item) async {
    _items.insert(0, item);
    return item;
  }

  @override
  Future<HomeItem> updateItem(HomeItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      throw const ApiException('Item was not found.');
    }
    _items[index] = item;
    return item;
  }

  @override
  Future<void> archiveItem(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw const ApiException('Item was not found.');
    }
    _archivedItems.insert(0, _items.removeAt(index));
  }

  @override
  Future<HomeItem> restoreItem(String itemId) async {
    final index = _archivedItems.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw const ApiException('Item was not found.');
    }
    final restored = _archivedItems.removeAt(index);
    _items.insert(0, restored);
    return restored;
  }
}

final homeItemRepositoryProvider = Provider<HomeItemRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockHomeItemRepository();
  }
  return RemoteHomeItemRepository(ref.watch(apiClientProvider), HomeItemCache());
});
