import '../../../core/localization/app_localizations.dart';

extension ItemLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get itemDetails => _isRussian ? 'Карточка вещи' : 'Item details';
  String get editItem => _isRussian ? 'Редактировать вещь' : 'Edit item';
  String get archiveItem => _isRussian ? 'Архивировать' : 'Archive item';
  String get archiveItemTitle => _isRussian ? 'Архивировать вещь?' : 'Archive item?';
  String get archiveItemBody => _isRussian
      ? 'Вещь исчезнет из активного списка. Ее данные останутся на сервере.'
      : 'The item will be removed from the active list. Its data will remain on the server.';
  String get itemArchived => _isRussian ? 'Вещь перенесена в архив' : 'Item moved to archive';
  String get serialNumber => _isRussian ? 'Серийный номер' : 'Serial number';
  String get purchaseDate => _isRussian ? 'Дата покупки' : 'Purchase date';
  String get noValue => _isRussian ? 'Не указано' : 'Not specified';
  String get edit => _isRussian ? 'Редактировать' : 'Edit';
  String get archive => _isRussian ? 'Архивировать' : 'Archive';
  String get itemUpdated => _isRussian ? 'Изменения сохранены' : 'Changes saved';
  String get itemNotFound => _isRussian ? 'Вещь не найдена' : 'Item not found';
}
