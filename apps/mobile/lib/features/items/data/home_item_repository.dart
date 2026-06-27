import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/home_item.dart';
import 'home_item_cache.dart';

abstract class HomeItemRepository {
  Future<List<HomeItem>> loadItems();
  Future<HomeItem> createItem(HomeItem item);
  Future<HomeItem> updateItem(HomeItem item);
  Future<void> archiveItem(String itemId);
}

class RemoteHomeItemRepository implements HomeItemRepository {
  RemoteHomeItemRepository(this._client, this._cache);

  final Dio _client;
  final HomeItemCache _cache;

  @override
  Future<List<HomeItem>> loadItems() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/items');
      final payload = response.data;
      final itemsRaw = payload?['items'] as List<dynamic>? ?? const [];
      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(HomeItem.fromJson)
          .toList(growable: false);
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
        data: item.toUpdatePayload(),
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
      await _cache.write(cachedItems.where((item) => item.id != itemId).toList(growable: false));
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
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
            serialNumber: 'RT-AX58U-DEMO',
            purchaseDate: DateTime.now().subtract(const Duration(days: 150)),
            warrantyExpiresAt: DateTime.now().add(const Duration(days: 30)),
            notes: 'Restart it after a firmware update.',
          ),
          HomeItem(
            id: 'demo-washer',
            name: 'Washing machine',
            category: 'appliance',
            location: 'Bathroom',
            purchaseDate: DateTime.now().subtract(const Duration(days: 420)),
            warrantyExpiresAt: DateTime.now().add(const Duration(days: 310)),
          ),
        ];

  final List<HomeItem> _items;

  @override
  Future<List<HomeItem>> loadItems() async => List.unmodifiable(_items);

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
    final removed = _items.removeWhere((item) => item.id == itemId);
    if (removed == 0) {
      throw const ApiException('Item was not found.');
    }
  }
}

final homeItemRepositoryProvider = Provider<HomeItemRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockHomeItemRepository();
  }
  return RemoteHomeItemRepository(ref.watch(apiClientProvider), HomeItemCache());
});
