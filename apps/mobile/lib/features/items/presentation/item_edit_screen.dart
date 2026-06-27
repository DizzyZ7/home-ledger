import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../domain/home_item.dart';
import 'item_form_screen.dart';
import 'item_localizations.dart';

class ItemEditScreen extends ConsumerWidget {
  const ItemEditScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemListControllerProvider);
    final l10n = context.l10n;

    return items.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.editItem)),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (data) {
        HomeItem? item;
        for (final candidate in data) {
          if (candidate.id == itemId) {
            item = candidate;
            break;
          }
        }
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.editItem)),
            body: Center(child: Text(l10n.itemNotFound)),
          );
        }
        return ItemFormScreen(item: item);
      },
    );
  }
}
