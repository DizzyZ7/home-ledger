import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../items/domain/home_item.dart';
import '../../items/presentation/warranty_localizations.dart';
import '../../maintenance/presentation/maintenance_list_controller.dart';
import 'dashboard_localizations.dart';

class DashboardAttentionSummary extends ConsumerWidget {
  const DashboardAttentionSummary({required this.items, super.key});

  final List<HomeItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final maintenance = ref.watch(maintenanceListControllerProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final warrantyDeadline = today.add(const Duration(days: 45));
    final warrantyAtRisk = items.where((item) {
      final warranty = item.warrantyExpiresAt;
      return warranty != null && !DateUtils.dateOnly(warranty).isAfter(warrantyDeadline);
    }).length;

    return Column(
      children: [
        _AttentionCard(
          key: const ValueKey('warranty-attention-card'),
          icon: Icons.verified_user_outlined,
          title: l10n.warranties,
          subtitle: warrantyAtRisk == 0 ? l10n.noWarrantyRisk : l10n.warrantyRiskCount(warrantyAtRisk),
          isUrgent: warrantyAtRisk > 0,
          onTap: () => context.push('/warranties'),
        ),
        const SizedBox(height: 8),
        maintenance.when(
          loading: () => _AttentionCard(
            key: const ValueKey('maintenance-attention-card'),
            icon: Icons.build_outlined,
            title: l10n.maintenanceNeedsAttention,
            subtitle: l10n.maintenanceLoading,
            onTap: () => context.push('/maintenance'),
          ),
          error: (_, __) => _AttentionCard(
            key: const ValueKey('maintenance-attention-card'),
            icon: Icons.cloud_off_outlined,
            title: l10n.maintenanceNeedsAttention,
            subtitle: l10n.maintenanceUnavailable,
            onTap: () => context.push('/maintenance'),
          ),
          data: (tasks) {
            final overdue = tasks.where((task) {
              return DateUtils.dateOnly(task.nextDueDate).isBefore(today);
            }).length;
            return _AttentionCard(
              key: const ValueKey('maintenance-attention-card'),
              icon: Icons.build_outlined,
              title: l10n.maintenanceNeedsAttention,
              subtitle: overdue == 0 ? l10n.noOverdueMaintenance : l10n.overdueMaintenanceCount(overdue),
              isUrgent: overdue > 0,
              onTap: () => context.push('/maintenance'),
            );
          },
        ),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isUrgent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isUrgent ? colorScheme.error : colorScheme.primary;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: isUrgent ? accent : colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
