import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/home_item.dart';

class HomeItemCache {
  HomeItemCache({String? householdId, String? userId})
      : _itemsKey = _buildItemsKey(householdId: householdId, userId: userId);

  static const _boxName = 'homeledger_items_v1';
  static const _defaultItemsKey = 'items';

  final String _itemsKey;

  static String _buildItemsKey({String? householdId, String? userId}) {
    if (userId != null && householdId != null) {
      return '$_defaultItemsKey:user:$userId:household:$householdId';
    }
    if (householdId != null) {
      return '$_defaultItemsKey:household:$householdId';
    }
    if (userId != null) {
      return '$_defaultItemsKey:user:$userId';
    }
    return _defaultItemsKey;
  }

  Future<List<HomeItem>> read() async {
    final box = await Hive.openBox<String>(_boxName);
    final raw = box.get(_itemsKey);
    if (raw == null) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(HomeItem.fromJson)
        .toList(growable: false);
  }

  Future<void> write(List<HomeItem> items) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_itemsKey, jsonEncode(items.map((item) => item.toJson()).toList()));
  }

  static Future<void> clearAll() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.clear();
    } on Object {
      // Optional offline data must never block a local sign-out.
    }
  }
}
