import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../items/domain/home_item.dart';

final inventorySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

List<HomeItem> filterInventoryItems(Iterable<HomeItem> items, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) {
    return List.unmodifiable(items.toList(growable: false));
  }

  return List.unmodifiable(
    items.where((item) {
      final fields = [
        item.name,
        item.category,
        item.location,
        item.serialNumber,
        item.notes,
      ];
      return fields.whereType<String>().any((field) => _normalize(field).contains(normalizedQuery));
    }).toList(growable: false),
  );
}

String inventorySearchEmptyTitle(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ru' ? 'Ничего не найдено' : 'No matching items';
}

String inventorySearchEmptyBody(BuildContext context, String query) {
  return Localizations.localeOf(context).languageCode == 'ru'
      ? 'Попробуйте изменить запрос «$query».'
      : 'Try changing “$query”.';
}

String _normalize(String value) => value.trim().toLowerCase();

class InventorySearchField extends ConsumerStatefulWidget {
  const InventorySearchField({super.key});

  @override
  ConsumerState<InventorySearchField> createState() => _InventorySearchFieldState();
}

class _InventorySearchFieldState extends ConsumerState<InventorySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(inventorySearchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(inventorySearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(inventorySearchQueryProvider);
    final hint = Localizations.localeOf(context).languageCode == 'ru'
        ? 'Поиск по инвентарю'
        : 'Search inventory';
    final clearTooltip = Localizations.localeOf(context).languageCode == 'ru' ? 'Очистить поиск' : 'Clear search';

    return TextField(
      key: const ValueKey('inventory-search-input'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (value) => ref.read(inventorySearchQueryProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: clearTooltip,
                icon: const Icon(Icons.clear),
                onPressed: _clear,
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
