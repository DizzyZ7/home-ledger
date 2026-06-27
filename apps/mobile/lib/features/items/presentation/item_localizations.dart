import '../../../core/localization/app_localizations.dart';

extension ItemLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get itemDetails => _isRussian ? 'Карточка вещи' : 'Item details';
  String get editItem => _isRussian ? 'Редактировать вещь' : 'Edit item';
  String get archive => _isRussian ? 'Архив' : 'Archive';
  String get archiveItem => _isRussian ? 'Архивировать вещь' : 'Archive item';
  String get archiveConfirmTitle => _isRussian ? 'Архивировать вещь?' : 'Archive item?';
  String get archiveConfirmBody => _isRussian
      ? 'Вещь исчезнет из активного инвентаря. Ее можно будет восстановить в архиве.'
      : 'The item will leave active inventory. You can restore it from the archive.';
  String get itemArchived => _isRussian ? 'Вещь перемещена в архив' : 'Item moved to archive';
  String get restoreItem => _isRussian ? 'Восстановить вещь' : 'Restore item';
  String get restoreConfirmTitle => _isRussian ? 'Восстановить вещь?' : 'Restore item?';
  String get restoreConfirmBody => _isRussian
      ? 'Вещь снова появится в активном инвентаре.'
      : 'The item will return to active inventory.';
  String get itemRestored => _isRussian ? 'Вещь восстановлена' : 'Item restored';
  String get archiveEmptyTitle => _isRussian ? 'Архив пуст' : 'Archive is empty';
  String get archiveEmptyBody => _isRussian
      ? 'Архивированные вещи появятся здесь, и их можно будет вернуть в инвентарь.'
      : 'Archived items will appear here and can be restored to inventory.';
  String get itemUpdated => _isRussian ? 'Изменения сохранены' : 'Changes saved';
  String get serialNumber => _isRussian ? 'Серийный номер' : 'Serial number';
  String get purchaseDate => _isRussian ? 'Дата покупки' : 'Purchase date';
  String get notSpecified => _isRussian ? 'Не указано' : 'Not specified';
  String get unavailableItem => _isRussian ? 'Вещь недоступна' : 'Item unavailable';
  String get fieldCategory => _isRussian ? 'Категория' : 'Category';
}
