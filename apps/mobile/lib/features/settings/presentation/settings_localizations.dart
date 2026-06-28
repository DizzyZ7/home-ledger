import 'package:flutter/widgets.dart';

import '../../../core/config/app_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/settings/app_settings.dart';

extension SettingsLocalizations on BuildContext {
  String get settingsTitle => l10n.languageCode == 'ru' ? 'Настройки' : 'Settings';

  String get appearanceSection => l10n.languageCode == 'ru' ? 'Оформление' : 'Appearance';

  String get themeSection => l10n.languageCode == 'ru' ? 'Тема' : 'Theme';

  String themeLabel(AppThemePreference preference) {
    return switch ((l10n.languageCode, preference)) {
      ('ru', AppThemePreference.system) => 'Как в системе',
      ('ru', AppThemePreference.light) => 'Светлая',
      ('ru', AppThemePreference.dark) => 'Темная',
      ('en', AppThemePreference.system) => 'System default',
      ('en', AppThemePreference.light) => 'Light',
      ('en', AppThemePreference.dark) => 'Dark',
      _ => 'System default',
    };
  }

  String get languageSection => l10n.languageCode == 'ru' ? 'Язык' : 'Language';

  String get dataSection => l10n.languageCode == 'ru' ? 'Данные и подключение' : 'Data and connection';

  String connectionMode(AppConfig config) {
    if (config.useMockData) {
      return l10n.languageCode == 'ru' ? 'Демо-режим' : 'Demo mode';
    }
    return l10n.languageCode == 'ru' ? 'Подключение к серверу' : 'Server connection';
  }

  String connectionDescription(AppConfig config) {
    if (config.useMockData) {
      return l10n.languageCode == 'ru'
          ? 'Данные хранятся только в приложении и не отправляются на сервер.'
          : 'Data stays in the app and is not sent to a server.';
    }
    return config.apiBaseUrl;
  }

  String get privacySection => l10n.languageCode == 'ru' ? 'Приватность' : 'Privacy';

  String get privacyBody => l10n.languageCode == 'ru'
      ? 'HomeLedger не передает инвентарь третьим лицам. При self-hosted установке данные остаются на выбранном вами сервере.'
      : 'HomeLedger does not share inventory with third parties. In a self-hosted setup, data stays on the server you choose.';

  String get appSection => l10n.languageCode == 'ru' ? 'Приложение' : 'Application';

  String get versionLabel => l10n.languageCode == 'ru' ? 'Версия 0.1.0' : 'Version 0.1.0';
}
