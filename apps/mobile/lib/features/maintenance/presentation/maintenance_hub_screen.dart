import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import 'maintenance_localizations.dart';
import 'maintenance_screen.dart';

class MaintenanceHubScreen extends StatelessWidget {
  const MaintenanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      fit: StackFit.expand,
      children: [
        const MaintenanceScreen(),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'homeledger-add-maintenance',
            onPressed: () => context.push('/maintenance/new'),
            icon: const Icon(Icons.add),
            label: Text(l10n.addMaintenance),
          ),
        ),
      ],
    );
  }
}
