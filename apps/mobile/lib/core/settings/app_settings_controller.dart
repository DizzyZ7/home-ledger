import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';
import 'app_settings_store.dart';

final appSettingsStoreProvider = Provider<AppSettingsStore>((ref) => AppSettingsStore());

final appSettingsControllerProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    unawaited(_restore());
    return const AppSettings.defaults();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'ru' && locale.languageCode != 'en') {
      return;
    }
    await _save(state.copyWith(locale: Locale(locale.languageCode)));
  }

  Future<void> toggleLanguage() {
    final locale = state.locale.languageCode == 'ru' ? const Locale('en') : const Locale('ru');
    return setLocale(locale);
  }

  Future<void> setThemePreference(AppThemePreference preference) {
    return _save(state.copyWith(themePreference: preference));
  }

  Future<void> _restore() async {
    try {
      final restored = await ref.read(appSettingsStoreProvider).read();
      state = restored;
    } on Object {
      // The app remains usable with in-memory defaults when optional storage is unavailable.
    }
  }

  Future<void> _save(AppSettings next) async {
    state = next;
    try {
      await ref.read(appSettingsStoreProvider).write(next);
    } on Object {
      // UI state remains valid even when optional persistence fails.
    }
  }
}
