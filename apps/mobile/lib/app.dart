import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/presentation/session_controller.dart';
import 'features/dashboard/presentation/dashboard_shell.dart';
import 'features/items/domain/home_item.dart';
import 'features/items/presentation/archived_items_screen.dart';
import 'features/items/presentation/item_detail_screen.dart';
import 'features/items/presentation/item_form_screen.dart';
import 'features/items/presentation/warranty_screen.dart';
import 'features/maintenance/domain/maintenance_task.dart';
import 'features/maintenance/presentation/maintenance_form_screen.dart';
import 'features/maintenance/presentation/maintenance_history_screen.dart';
import 'features/maintenance/presentation/maintenance_screen.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('ru'));

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SessionGate(),
        routes: [
          GoRoute(
            path: 'items/new',
            builder: (context, state) => const ItemFormScreen(),
          ),
          GoRoute(
            path: 'items/archived',
            builder: (context, state) => const ArchivedItemsScreen(),
          ),
          GoRoute(
            path: 'items/:itemId',
            builder: (context, state) => ItemDetailScreen(
              itemId: state.pathParameters['itemId']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final item = state.extra;
                  if (item is HomeItem) {
                    return ItemFormScreen(item: item);
                  }
                  return const _MissingItemRoute();
                },
              ),
              GoRoute(
                path: 'maintenance-history',
                builder: (context, state) {
                  final item = state.extra;
                  return MaintenanceHistoryScreen(
                    itemId: state.pathParameters['itemId']!,
                    itemName: item is HomeItem ? item.name : null,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'warranties',
            builder: (context, state) => const WarrantyScreen(),
          ),
          GoRoute(
            path: 'maintenance/history',
            builder: (context, state) => const MaintenanceHistoryScreen(),
          ),
          GoRoute(
            path: 'maintenance/new',
            builder: (context, state) {
              final item = state.extra;
              return MaintenanceFormScreen(initialItem: item is HomeItem ? item : null);
            },
          ),
          GoRoute(
            path: 'maintenance/:taskId/edit',
            builder: (context, state) {
              final task = state.extra;
              if (task is MaintenanceTask) {
                return MaintenanceFormScreen(task: task);
              }
              return const _MissingMaintenanceRoute();
            },
          ),
          GoRoute(
            path: 'maintenance',
            builder: (context, state) => const MaintenanceScreen(),
          ),
        ],
      ),
    ],
  );
});

class HomeLedgerApp extends ConsumerWidget {
  const HomeLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HomeLedger',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final session = ref.watch(sessionControllerProvider);

    return session.when(
      loading: () => const _LaunchScreen(),
      error: (_, __) => AuthScreen(showMockHint: config.useMockData),
      data: (value) {
        if (value == null) {
          return AuthScreen(showMockHint: config.useMockData);
        }
        return const DashboardShell();
      },
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MissingItemRoute extends StatelessWidget {
  const _MissingItemRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(context.l10n.errorGeneric)),
    );
  }
}

class _MissingMaintenanceRoute extends StatelessWidget {
  const _MissingMaintenanceRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(context.l10n.errorGeneric)),
    );
  }
}
