import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/maintenance_task.dart';
import 'maintenance_list_controller.dart';
import 'maintenance_localizations.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String? _completingTaskId;

  Future<void> _completeTask(MaintenanceTask task) async {
    setState(() => _completingTaskId = task.id);
    try {
      await ref.read(maintenanceListControllerProvider.notifier).completeTask(task.id);
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
    final tasks = ref.watch(maintenanceListControllerProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.maintenance)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MaintenanceErrorState(
          onRetry: () => ref.read(maintenanceListControllerProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.isEmpty) {
            return const _MaintenanceEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(maintenanceListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = data[index];
                return _MaintenanceTaskTile(
                  task: task,
                  isCompleting: _completingTaskId == task.id,
                  onComplete: () => _completeTask(task),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceTaskTile extends StatelessWidget {
  const _MaintenanceTaskTile({
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
    final isOverdue = DateUtils.dateOnly(task.nextDueDate).isBefore(DateUtils.dateOnly(DateTime.now()));
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${task.title}. $dueText',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isOverdue ? Icons.priority_high_outlined : Icons.build_outlined,
                    color: isOverdue ? colorScheme.error : colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          dueText,
                          style: TextStyle(
                            color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (task.notes != null && task.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(task.notes!),
              ],
              const SizedBox(height: 16),
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
        ),
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

class _MaintenanceEmptyState extends StatelessWidget {
  const _MaintenanceEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.noMaintenanceTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.noMaintenanceBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceErrorState extends StatelessWidget {
  const _MaintenanceErrorState({required this.onRetry});

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
