import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../auth/presentation/session_controller.dart';
import 'settings_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final config = ref.watch(appConfigProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionTitle(text: context.appearanceSection),
          Card(
            child: RadioGroup<AppThemePreference>(
              groupValue: settings.themePreference,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemePreference(value);
                }
              },
              child: Column(
                children: [
                  for (final preference in AppThemePreference.values)
                    RadioListTile<AppThemePreference>(
                      key: ValueKey('settings-theme-${preference.name}'),
                      value: preference,
                      title: Text(context.themeLabel(preference)),
                      secondary: Icon(_themeIcon(preference)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: context.languageSection),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<String>(
                key: const ValueKey('settings-language-selector'),
                segments: const [
                  ButtonSegment(value: 'ru', label: Text('Русский')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.locale.languageCode},
                onSelectionChanged: (selection) {
                  controller.setLocale(Locale(selection.first));
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: context.dataSection),
          Card(
            child: ListTile(
              leading: Icon(config.useMockData ? Icons.science_outlined : Icons.cloud_outlined),
              title: Text(context.connectionMode(config)),
              subtitle: Text(context.connectionDescription(config)),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: context.privacySection),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.privacyBody)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: context.appSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('HomeLedger'),
                  subtitle: Text(context.versionLabel),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey('settings-sign-out'),
                  leading: const Icon(Icons.logout_outlined),
                  title: Text(context.l10n.signOut),
                  onTap: () => ref.read(sessionControllerProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(AppThemePreference preference) {
    return switch (preference) {
      AppThemePreference.system => Icons.brightness_auto_outlined,
      AppThemePreference.light => Icons.light_mode_outlined,
      AppThemePreference.dark => Icons.dark_mode_outlined,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
