import '../../../core/localization/app_localizations.dart';

extension ItemLocalizations on AppLocalizations {
  String get itemDetails => languageCode == 'ru' ? 'Карточка вещи' : 'Item details';
}
