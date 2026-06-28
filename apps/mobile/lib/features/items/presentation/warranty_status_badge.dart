import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/home_item.dart';
import '../domain/warranty_health.dart';
import 'warranty_status_localizations.dart';

class WarrantyStatusBadge extends StatelessWidget {
  const WarrantyStatusBadge({required this.item, super.key});

  final HomeItem item;

  @override
  Widget build(BuildContext context) {
    final health = resolveWarrantyHealth(item.warrantyExpiresAt);
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (health) {
      WarrantyHealth.none => colorScheme.outline,
      WarrantyHealth.expired => colorScheme.error,
      WarrantyHealth.expiring => colorScheme.tertiary,
      WarrantyHealth.protected => colorScheme.primary,
    };
    final icon = switch (health) {
      WarrantyHealth.none => Icons.remove_circle_outline,
      WarrantyHealth.expired => Icons.error_outline,
      WarrantyHealth.expiring => Icons.schedule_outlined,
      WarrantyHealth.protected => Icons.verified_outlined,
    };
    final label = l10n.warrantyHealthLabel(health);

    return Semantics(
      label: label,
      child: Container(
        key: ValueKey('warranty-status-${item.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withAlpha(28),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
