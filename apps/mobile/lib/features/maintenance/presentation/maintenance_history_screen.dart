import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/maintenance_completion.dart';
import 'maintenance_history_controller.dart';
import 'maintenance_localizations.dart';

class MaintenanceHistoryScreen extends ConsumerWidget {
  const MaintenanceHistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(maintenanceHistoryProvider);
    await ref.read(maintenanceHistoryProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(maintenanceHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.maintenanceHistory)),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _HistoryErrorState(onRetry: () => _refresh(ref)),
        data: (entries) {
          if (entries.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [_HistoryEmptyState()],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _CompletionTile(entry: entries[index]),
            ),
          );
        },
      ),
    );
  }
}

class _CompletionTile extends StatelessWidget {
  const _CompletionTile({required this.entry});

  final MaintenanceCompletion entry;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final localTime = entry.completedAt.toLocal();
    final timestamp = '${localizations.formatMediumDate(localTime)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localTime))}';
    final l10n = context.l10n;

    return Semantics(
      label: '${entry.taskTitle}. ${l10n.itemContext(entry.itemName)}. ${l10n.completedAt(timestamp)}',
      child: Card(
        child: ListTile(
          key: ValueKey('maintenance-history-${entry.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.check_circle_outline),
          title: Text(entry.taskTitle),
          subtitle: Text('${l10n.itemContext(entry.itemName)}\n${l10n.completedAt(timestamp)}'),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          const Icon(Icons.history_outlined, size: 48),
          const SizedBox(height: 16),
          Text(l10n.noMaintenanceHistoryTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.noMaintenanceHistoryBody, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.onRetry});

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
