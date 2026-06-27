import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/home_item.dart';
import 'archived_item_list_controller.dart';
import 'item_localizations.dart';

class ArchivedItemsScreen extends ConsumerStatefulWidget {
  const ArchivedItemsScreen({super.key});

  @override
  ConsumerState<ArchivedItemsScreen> createState() => _ArchivedItemsScreenState();
}

class _ArchivedItemsScreenState extends ConsumerState<ArchivedItemsScreen> {
  String? _restoringItemId;

  Future<void> _restore(HomeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.restoreItem),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _restoringItemId = item.id);
    try {
      await ref.read(archivedItemListControllerProvider.notifier).restoreItem(item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.itemRestored)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _restoringItemId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final archivedItems = ref.watch(archivedItemListControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archive)),
      body: archivedItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ArchiveErrorState(
          onRetry: () => ref.read(archivedItemListControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _ArchiveEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(archivedItemListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ArchivedItemTile(
                  item: item,
                  restoring: _restoringItemId == item.id,
                  onRestore: () => _restore(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ArchivedItemTile extends StatelessWidget {
  const _ArchivedItemTile({
    required this.item,
    required this.restoring,
    required this.onRestore,
  });

  final HomeItem item;
  final bool restoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = item.location ?? l10n.notSpecified;
    final avatar = item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase();

    return Semantics(
      label: '${item.name}. ${l10n.archive}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(avatar)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${item.category} · $location'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: restoring ? null : onRestore,
                  icon: restoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.unarchive_outlined),
                  label: Text(l10n.restoreItem),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveEmptyState extends StatelessWidget {
  const _ArchiveEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.archiveEmptyTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.archiveEmptyBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ArchiveErrorState extends StatelessWidget {
  const _ArchiveErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
            Text(context.l10n.errorGeneric, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
