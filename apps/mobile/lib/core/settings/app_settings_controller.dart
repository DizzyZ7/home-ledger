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
    final restored = await ref.read(appSettingsStoreProvider).read();
    state = restored;
  }

  Future<void> _save(AppSettings next) async {
    state = next;
    await ref.read(appSettingsStoreProvider).write(next);
  }
}
