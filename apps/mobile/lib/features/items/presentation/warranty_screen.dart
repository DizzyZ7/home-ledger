import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/home_item.dart';
import 'warranty_localizations.dart';
import 'warranty_overview_provider.dart';

class WarrantyScreen extends ConsumerWidget {
  const WarrantyScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(warrantyOverviewProvider);
    await ref.read(warrantyOverviewProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref.watch(warrantyOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warranties)),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _WarrantyErrorState(onRetry: () => _refresh(ref)),
        data: (data) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _WarrantyIntro(),
              const SizedBox(height: 16),
              _WarrantySection(
                icon: Icons.warning_amber_outlined,
                title: l10n.expiredWarranties,
                emptyText: l10n.noExpiredWarranties,
                items: data.expiredItems,
                expired: true,
              ),
              const SizedBox(height: 16),
              _WarrantySection(
                icon: Icons.event_available_outlined,
                title: l10n.expiringWarranties,
                emptyText: l10n.noExpiringWarranties,
                items: data.expiringItems,
                expired: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarrantyIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.warrantyOverviewBody),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantySection extends StatelessWidget {
  const _WarrantySection({
    required this.icon,
    required this.title,
    required this.emptyText,
    required this.items,
    required this.expired,
  });

  final IconData icon;
  final String title;
  final String emptyText;
  final List<HomeItem> items;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: expired ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            Text('${items.length}', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyText),
            ),
          )
        else
          ...items.map((item) => _WarrantyItemTile(item: item, expired: expired)),
      ],
    );
  }
}

class _WarrantyItemTile extends StatelessWidget {
  const _WarrantyItemTile({required this.item, required this.expired});

  final HomeItem item;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final warrantyDate = item.warrantyExpiresAt!;
    final status = _statusText(context, warrantyDate);
    final date = MaterialLocalizations.of(context).formatMediumDate(warrantyDate);
    final avatarText = item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${item.name}. $status',
      button: true,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(child: Text(avatarText)),
          title: Text(item.name),
          subtitle: Text('${item.location ?? item.category} · $date\n$status'),
          isThreeLine: true,
          trailing: Icon(
            expired ? Icons.priority_high_outlined : Icons.chevron_right,
            color: expired ? colorScheme.error : null,
          ),
          onTap: () => context.push('/items/${item.id}'),
        ),
      ),
    );
  }

  String _statusText(BuildContext context, DateTime warrantyDate) {
    final l10n = context.l10n;
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(warrantyDate);
    final days = due.difference(today).inDays;
    if (days < 0) {
      return l10n.warrantyExpiredBy(-days);
    }
    if (days == 0) {
      return l10n.warrantyEndsToday;
    }
    return l10n.warrantyEndsIn(days);
  }
}

class _WarrantyErrorState extends StatelessWidget {
  const _WarrantyErrorState({required this.onRetry});

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
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
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
