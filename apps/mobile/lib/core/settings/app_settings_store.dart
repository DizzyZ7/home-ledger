import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_settings.dart';

class AppSettingsStore {
  static const _boxName = 'homeledger_settings_v1';
  static const _languageKey = 'language_code';
  static const _themeKey = 'theme_preference';

  Future<AppSettings> read() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final languageCode = box.get(_languageKey);
      final themeValue = box.get(_themeKey);
      return AppSettings(
        locale: Locale(_supportedLanguage(languageCode)),
        themePreference: _themePreference(themeValue),
      );
    } on Object {
      return const AppSettings.defaults();
    }
  }

  Future<void> write(AppSettings settings) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(_languageKey, settings.locale.languageCode);
      await box.put(_themeKey, settings.themePreference.name);
    } on Object {
      // Settings persistence is optional and must not block the app.
    }
  }

  String _supportedLanguage(String? value) => value == 'en' ? 'en' : 'ru';

  AppThemePreference _themePreference(String? value) {
    return switch (value) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }
}
