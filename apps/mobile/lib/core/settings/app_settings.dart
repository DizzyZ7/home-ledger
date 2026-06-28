import 'package:flutter/material.dart';

@immutable
class AppSettings {
  const AppSettings({
    required this.locale,
    required this.themePreference,
  });

  const AppSettings.defaults()
      : locale = const Locale('ru'),
        themePreference = AppThemePreference.system;

  final Locale locale;
  final AppThemePreference themePreference;

  ThemeMode get themeMode => switch (themePreference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  AppSettings copyWith({
    Locale? locale,
    AppThemePreference? themePreference,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

enum AppThemePreference { system, light, dark }
