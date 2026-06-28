import '../../../core/localization/app_localizations.dart';

extension WarrantyLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get warranties => _isRussian ? 'Гарантии' : 'Warranties';
  String get expiredWarranties => _isRussian ? 'Гарантия истекла' : 'Warranty expired';
  String get expiringWarranties => _isRussian ? 'Скоро заканчиваются' : 'Expiring soon';
  String get noExpiredWarranties => _isRussian ? 'Нет истекших гарантий' : 'No expired warranties';
  String get noExpiringWarranties => _isRussian
      ? 'В ближайшие 45 дней гарантия не заканчивается'
      : 'No warranties expire in the next 45 days';
  String get warrantyOverviewBody => _isRussian
      ? 'Проверьте срок и откройте вещь, чтобы увидеть серийный номер и детали.'
      : 'Review the deadline, then open an item for its serial number and details.';
  String get warrantyEndsToday => _isRussian ? 'Заканчивается сегодня' : 'Ends today';

  String warrantyExpiredBy(int days) => _isRussian ? 'Истекла $days дн. назад' : 'Expired $days days ago';
  String warrantyEndsIn(int days) => _isRussian ? 'Заканчивается через $days дн.' : 'Ends in $days days';
}
