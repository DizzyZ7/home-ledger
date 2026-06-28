import 'package:flutter/widgets.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/household_summary.dart';

extension HouseholdLocalizations on BuildContext {
  String get householdTitle => l10n.languageCode == 'ru' ? 'Дом' : 'Household';

  String get householdSubtitle => l10n.languageCode == 'ru'
      ? 'Выберите дом, с которым вы сейчас работаете.'
      : 'Choose the household you are working with.';

  String get householdActive => l10n.languageCode == 'ru' ? 'Активный дом' : 'Active household';

  String householdRole(HouseholdRole role) {
    return switch ((l10n.languageCode, role)) {
      ('ru', HouseholdRole.owner) => 'Владелец',
      ('ru', HouseholdRole.member) => 'Участник',
      ('en', HouseholdRole.owner) => 'Owner',
      ('en', HouseholdRole.member) => 'Member',
      _ => 'Member',
    };
  }

  String get householdSwitched => l10n.languageCode == 'ru' ? 'Активный дом изменен.' : 'Active household changed.';

  String get noHouseholdsTitle => l10n.languageCode == 'ru' ? 'Нет доступных домов' : 'No households available';

  String get noHouseholdsBody => l10n.languageCode == 'ru'
      ? 'Создайте аккаунт заново или попросите владельца добавить вас в общий дом.'
      : 'Create an account again or ask an owner to add you to a shared household.';
}
