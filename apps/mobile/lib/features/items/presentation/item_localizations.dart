import '../../../core/localization/app_localizations.dart';

extension ItemLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get itemDetails => _isRussian ? 'Карточка вещи' : 'Item details';
  String get editItem => _isRussian ? 'Редактировать вещь' : 'Edit item';
  String get archiveItem => _isRussian ? 'Архивировать вещь' : 'Archive item';
  String get archiveConfirmTitle => _isRussian ? 'Архивировать вещь?' : 'Archive item?';
  String get archiveConfirmBody => _isRussian
      ? 'Вещь исчезнет из активного инвентаря. Восстановление появится в будущем экране архива.'
      : 'The item will leave active inventory. Restoration will be available in a future archive screen.';
  String get itemArchived => _isRussian ? 'Вещь перемещена в архив' : 'Item moved to archive';
  String get itemUpdated => _isRussian ? 'Изменения сохранены' : 'Changes saved';
  String get serialNumber => _isRussian ? 'Серийный номер' : 'Serial number';
  String get purchaseDate => _isRussian ? 'Дата покупки' : 'Purchase date';
  String get notSpecified => _isRussian ? 'Не указано' : 'Not specified';
  String get unavailableItem => _isRussian ? 'Вещь недоступна' : 'Item unavailable';
  String get fieldCategory => _isRussian ? 'Категория' : 'Category';
}
