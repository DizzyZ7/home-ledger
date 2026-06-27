import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ru'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get languageCode => locale.languageCode;

  String get appTitle => _value('appTitle');
  String get signIn => _value('signIn');
  String get createAccount => _value('createAccount');
  String get email => _value('email');
  String get password => _value('password');
  String get displayName => _value('displayName');
  String get continueLabel => _value('continue');
  String get haveAccount => _value('haveAccount');
  String get noAccount => _value('noAccount');
  String get mockMode => _value('mockMode');
  String get inventory => _value('inventory');
  String get addItem => _value('addItem');
  String get itemName => _value('itemName');
  String get category => _value('category');
  String get location => _value('location');
  String get warrantyUntil => _value('warrantyUntil');
  String get notes => _value('notes');
  String get save => _value('save');
  String get cancel => _value('cancel');
  String get retry => _value('retry');
  String get emptyTitle => _value('emptyTitle');
  String get emptyBody => _value('emptyBody');
  String get loading => _value('loading');
  String get noWarranty => _value('noWarranty');
  String get language => _value('language');
  String get signOut => _value('signOut');
  String get errorGeneric => _value('errorGeneric');
  String get requiredField => _value('requiredField');
  String get attention => _value('attention');
  String get allItems => _value('allItems');
  String get itemSaved => _value('itemSaved');

  String warrantyDate(String date) => _value('warrantyDate').replaceFirst('{date}', date);

  String _value(String key) => _strings[locale.languageCode]?[key] ?? _strings['en']![key]!;

  static const _strings = <String, Map<String, String>>{
    'ru': {
      'appTitle': 'HomeLedger',
      'signIn': 'Войти',
      'createAccount': 'Создать аккаунт',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'displayName': 'Как к вам обращаться',
      'continue': 'Продолжить',
      'haveAccount': 'Уже есть аккаунт? Войти',
      'noAccount': 'Нет аккаунта? Создать',
      'mockMode': 'Демо-режим активен. Никакие данные не отправляются на сервер.',
      'inventory': 'Мои вещи',
      'addItem': 'Добавить вещь',
      'itemName': 'Название',
      'category': 'Категория',
      'location': 'Где хранится',
      'warrantyUntil': 'Гарантия до',
      'notes': 'Заметка',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'retry': 'Повторить',
      'emptyTitle': 'Пока нет вещей',
      'emptyBody': 'Добавьте первую вещь, чтобы не терять данные о гарантии и обслуживании.',
      'loading': 'Загрузка',
      'noWarranty': 'Гарантия не указана',
      'language': 'Язык',
      'signOut': 'Выйти',
      'errorGeneric': 'Не удалось выполнить действие. Попробуйте еще раз.',
      'requiredField': 'Заполните поле',
      'attention': 'Требует внимания',
      'allItems': 'Все вещи',
      'itemSaved': 'Вещь сохранена',
      'warrantyDate': 'Гарантия до {date}',
    },
    'en': {
      'appTitle': 'HomeLedger',
      'signIn': 'Sign in',
      'createAccount': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'displayName': 'Display name',
      'continue': 'Continue',
      'haveAccount': 'Already have an account? Sign in',
      'noAccount': 'No account? Create one',
      'mockMode': 'Demo mode is enabled. No data is sent to a server.',
      'inventory': 'My items',
      'addItem': 'Add item',
      'itemName': 'Name',
      'category': 'Category',
      'location': 'Storage location',
      'warrantyUntil': 'Warranty until',
      'notes': 'Notes',
      'save': 'Save',
      'cancel': 'Cancel',
      'retry': 'Retry',
      'emptyTitle': 'No items yet',
      'emptyBody': 'Add your first item to keep warranty and maintenance details close.',
      'loading': 'Loading',
      'noWarranty': 'No warranty date',
      'language': 'Language',
      'signOut': 'Sign out',
      'errorGeneric': 'The action could not be completed. Please try again.',
      'requiredField': 'This field is required',
      'attention': 'Needs attention',
      'allItems': 'All items',
      'itemSaved': 'Item saved',
      'warrantyDate': 'Warranty until {date}',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.contains(Locale(locale.languageCode));

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
