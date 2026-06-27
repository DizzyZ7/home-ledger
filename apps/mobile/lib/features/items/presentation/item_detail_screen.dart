import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../domain/home_item.dart';
import 'item_localizations.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  var _archiving = false;

  Future<void> _archive(HomeItem item) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveItemTitle),
        content: Text(l10n.archiveItemBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _archiving = true);
    try {
      await ref.read(itemListControllerProvider.notifier).archive(item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.itemArchived)));
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _archiving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemListControllerProvider);
    final l10n = context.l10n;

    return items.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.itemDetails)),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (data) {
        HomeItem? item;
        for (final candidate in data) {
          if (candidate.id == widget.itemId) {
            item = candidate;
            break;
          }
        }
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.itemDetails)),
            body: Center(child: Text(l10n.itemNotFound)),
          );
        }
        return _ItemDetailBody(
          item: item,
          archiving: _archiving,
          onArchive: () => _archive(item!),
        );
      },
    );
  }
}

class _ItemDetailBody extends StatelessWidget {
  const _ItemDetailBody({
    required this.item,
    required this.archiving,
    required this.onArchive,
  });

  final HomeItem item;
  final bool archiving;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final purchaseText = item.purchaseDate == null
        ? l10n.noValue
        : localizations.formatMediumDate(item.purchaseDate!);
    final warrantyText = item.warrantyExpiresAt == null
        ? l10n.noWarranty
        : localizations.formatMediumDate(item.warrantyExpiresAt!);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.itemDetails),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context.push('/items/${item.id}/edit', extra: item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: l10n.archiveItem,
            onPressed: archiving ? null : onArchive,
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(item.category),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailCard(
            children: [
              _DetailRow(label: l10n.location, value: item.location ?? l10n.noValue),
              _DetailRow(label: l10n.serialNumber, value: item.serialNumber ?? l10n.noValue),
              _DetailRow(label: l10n.purchaseDate, value: purchaseText),
              _DetailRow(label: l10n.warrantyUntil, value: warrantyText),
            ],
          ),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailCard(
              children: [
                Text(l10n.notes, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(item.notes!),
              ],
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: archiving ? null : onArchive,
            icon: archiving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.archive_outlined),
            label: Text(l10n.archiveItem),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
