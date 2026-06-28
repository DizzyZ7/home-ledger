import '../../../core/localization/app_localizations.dart';

extension AttachmentLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get attachments => _isRussian ? 'Чеки и файлы' : 'Receipts and files';
  String get addAttachment => _isRussian ? 'Прикрепить файл' : 'Attach file';
  String get noAttachments => _isRussian ? 'Чеков и файлов пока нет' : 'No receipts or files yet';
  String get attachmentTypesHint => _isRussian
      ? 'Поддерживаются PDF, JPEG, PNG и WebP. Максимальный размер задает ваш сервер.'
      : 'PDF, JPEG, PNG and WebP are supported. Your server controls the size limit.';
  String get attachmentAdded => _isRussian ? 'Файл прикреплен' : 'File attached';
  String get attachmentDeleted => _isRussian ? 'Файл удален' : 'File deleted';
  String get openAttachment => _isRussian ? 'Открыть файл' : 'Open file';
  String get deleteAttachment => _isRussian ? 'Удалить файл' : 'Delete file';
  String get deleteAttachmentTitle => _isRussian ? 'Удалить файл?' : 'Delete file?';
  String get deleteAttachmentBody => _isRussian
      ? 'Файл будет удален из этого self-hosted хранилища без возможности восстановления.'
      : 'The file will be permanently removed from this self-hosted storage.';
  String get attachmentOpenFailed => _isRussian
      ? 'Не удалось открыть файл на устройстве.'
      : 'The file could not be opened on this device.';
  String get attachmentPickerFailed => _isRussian
      ? 'Не удалось прочитать выбранный файл.'
      : 'The selected file could not be read.';
}
