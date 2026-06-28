import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../maintenance/domain/maintenance_task.dart';
import '../../maintenance/presentation/item_maintenance_tasks_provider.dart';
import '../../maintenance/presentation/maintenance_history_controller.dart';
import '../../maintenance/presentation/maintenance_list_controller.dart';
import '../../maintenance/presentation/maintenance_localizations.dart';
import '../domain/home_item.dart';

class ItemMaintenanceSection extends ConsumerStatefulWidget {
  const ItemMaintenanceSection({
    required this.item,
    required this.onAddTask,
    required this.onOpenHistory,
    super.key,
  });

  final HomeItem item;
  final Future<void> Function() onAddTask;
  final VoidCallback onOpenHistory;

  @override
  ConsumerState<ItemMaintenanceSection> createState() => _ItemMaintenanceSectionState();
}

class _ItemMaintenanceSectionState extends ConsumerState<ItemMaintenanceSection> {
  String? _completingTaskId;

  Future<void> _completeTask(MaintenanceTask task) async {
    setState(() => _completingTaskId = task.id);
    try {
      await ref.read(maintenanceListControllerProvider.notifier).completeTask(task.id);
      ref.invalidate(maintenanceHistoryProvider(null));
      ref.invalidate(maintenanceHistoryProvider(widget.item.id));
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
                IconButton(
                  key: const ValueKey('item-maintenance-history-action'),
                  tooltip: l10n.maintenanceHistory,
                  icon: const Icon(Icons.history_outlined),
                  onPressed: widget.onOpenHistory,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onAddTask,
                icon: const Icon(Icons.add),
                label: Text(l10n.addMaintenance),
              ),
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
