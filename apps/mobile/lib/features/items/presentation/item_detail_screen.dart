import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../../maintenance/domain/maintenance_task.dart';
import '../../maintenance/presentation/item_maintenance_tasks_provider.dart';
import '../../maintenance/presentation/maintenance_list_controller.dart';
import '../../maintenance/presentation/maintenance_localizations.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.archiveConfirmTitle),
          content: Text(l10n.archiveConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.archiveItem),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _archiving = true);
    try {
      await ref.read(itemListControllerProvider.notifier).archiveItem(item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.itemArchived)),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
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
    return items.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _UnavailableItemState(onBack: context.pop),
      data: (data) {
        HomeItem? item;
        for (final candidate in data) {
          if (candidate.id == widget.itemId) {
            item = candidate;
            break;
          }
        }
        if (item == null) {
          return _UnavailableItemState(onBack: context.pop);
        }
        return _ItemDetails(item: item, archiving: _archiving, onArchive: () => _archive(item!));
      },
    );
  }
}

class _ItemDetails extends ConsumerWidget {
  const _ItemDetails({
    required this.item,
    required this.archiving,
    required this.onArchive,
  });

  final HomeItem item;
  final bool archiving;
  final VoidCallback onArchive;

  Future<void> _openMaintenanceForm(BuildContext context, WidgetRef ref) async {
    await context.push('/maintenance/new', extra: item);
    ref.invalidate(itemMaintenanceTasksProvider(item.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final warranty = item.warrantyExpiresAt == null
        ? l10n.notSpecified
        : localizations.formatMediumDate(item.warrantyExpiresAt!);
    final purchased = item.purchaseDate == null
        ? l10n.notSpecified
        : localizations.formatMediumDate(item.purchaseDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.itemDetails),
        actions: [
          IconButton(
            tooltip: l10n.editItem,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/items/${item.id}/edit', extra: item),
          ),
          IconButton(
            tooltip: l10n.archiveItem,
            icon: archiving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.archive_outlined),
            onPressed: archiving ? null : onArchive,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(item.category, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(label: l10n.location, value: item.location ?? l10n.notSpecified),
          _DetailRow(label: l10n.serialNumber, value: item.serialNumber ?? l10n.notSpecified),
          _DetailRow(label: l10n.purchaseDate, value: purchased),
          _DetailRow(label: l10n.warrantyUntil, value: warranty),
          if (item.notes != null && item.notes!.trim().isNotEmpty)
            _DetailRow(label: l10n.notes, value: item.notes!),
          const SizedBox(height: 12),
          _ItemMaintenanceSection(
            item: item,
            onAddTask: () => _openMaintenanceForm(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ItemMaintenanceSection extends ConsumerStatefulWidget {
  const _ItemMaintenanceSection({required this.item, required this.onAddTask});

  final HomeItem item;
  final Future<void> Function() onAddTask;

  @override
  ConsumerState<_ItemMaintenanceSection> createState() => _ItemMaintenanceSectionState();
}

class _ItemMaintenanceSectionState extends ConsumerState<_ItemMaintenanceSection> {
  String? _completingTaskId;

  Future<void> _completeTask(MaintenanceTask task) async {
    setState(() => _completingTaskId = task.id);
    try {
      await ref.read(maintenanceListControllerProvider.notifier).completeTask(task.id);
      ref.invalidate(itemMaintenanceTasksProvider(widget.item.id));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.taskCompleted)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _completingTaskId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tasks = ref.watch(itemMaintenanceTasksProvider(widget.item.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.maintenance, style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: () {
                    widget.onAddTask();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addMaintenance),
                ),
              ],
            ),
            const SizedBox(height: 8),
            tasks.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.errorGeneric),
                  TextButton(
                    onPressed: () => ref.invalidate(itemMaintenanceTasksProvider(widget.item.id)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Text(l10n.noMaintenanceForItem);
                }
                return Column(
                  children: [
                    for (final task in data)
                      _ItemMaintenanceTile(
                        task: task,
                        isCompleting: _completingTaskId == task.id,
                        onComplete: () => _completeTask(task),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMaintenanceTile extends StatelessWidget {
  const _ItemMaintenanceTile({
    required this.task,
    required this.isCompleting,
    required this.onComplete,
  });

  final MaintenanceTask task;
  final bool isCompleting;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dueText = _dueText(context, task.nextDueDate);
    final overdue = DateUtils.dateOnly(task.nextDueDate).isBefore(DateUtils.dateOnly(DateTime.now()));
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            key: ValueKey('item-maintenance-${task.id}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              overdue ? Icons.priority_high_outlined : Icons.build_outlined,
              color: overdue ? colorScheme.error : colorScheme.primary,
            ),
            title: Text(task.title),
            subtitle: Text(
              dueText,
              style: TextStyle(
                color: overdue ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              tooltip: l10n.editMaintenance,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/maintenance/${task.id}/edit', extra: task),
            ),
            onTap: () => context.push('/maintenance/${task.id}/edit', extra: task),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: isCompleting ? null : onComplete,
              icon: isCompleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(l10n.markComplete),
            ),
          ),
        ],
      ),
    );
  }

  String _dueText(BuildContext context, DateTime dueDate) {
    final l10n = context.l10n;
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(dueDate);
    final delta = due.difference(today).inDays;
    if (delta < 0) {
      return l10n.overdueBy(-delta);
    }
    if (delta == 0) {
      return l10n.dueToday;
    }
    return l10n.dueInDays(delta);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class _UnavailableItemState extends StatelessWidget {
  const _UnavailableItemState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 16),
              Text(l10n.unavailableItem, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onBack, child: Text(l10n.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}
