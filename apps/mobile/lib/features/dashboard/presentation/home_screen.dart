import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../../items/domain/home_item.dart';
import 'item_list_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemListControllerProvider);
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.language_outlined),
            onPressed: () {
              ref.read(localeProvider.notifier).state =
                  locale.languageCode == 'ru' ? const Locale('en') : const Locale('ru');
            },
          ),
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'homeledger-add-item',
        onPressed: () => context.push('/items/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addItem),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(onRetry: () => ref.read(itemListControllerProvider.notifier).refresh()),
        data: (data) {
          if (data.isEmpty) {
            return _EmptyState(onAdd: () => context.push('/items/new'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(itemListControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _AttentionSummary(items: data),
                const SizedBox(height: 16),
                Text(l10n.allItems, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...data.map((item) => _ItemTile(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AttentionSummary extends StatelessWidget {
  const _AttentionSummary({required this.items});

  final List<HomeItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deadline = DateTime.now().add(const Duration(days: 45));
    final expiring = items.where((item) {
      final warranty = item.warrantyExpiresAt;
      return warranty != null && warranty.isBefore(deadline);
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.attention, style: Theme.of(context).textTheme.titleSmall),
                  Text('$expiring ${l10n.inventory.toLowerCase()}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final HomeItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final warrantyText = item.warrantyExpiresAt == null
        ? l10n.noWarranty
        : l10n.warrantyDate(DateFormat.yMMMd(locale).format(item.warrantyExpiresAt!));
    final avatarText = item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase();

    return Semantics(
      label: '${item.name}. $warrantyText',
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(child: Text(avatarText)),
          title: Text(item.name),
          subtitle: Text([if (item.location != null) item.location!, warrantyText].join(' · ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/items/${item.id}'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.emptyTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.emptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(l10n.addItem)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.errorGeneric, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
