import '../../../core/localization/app_localizations.dart';
import '../domain/warranty_health.dart';

extension WarrantyStatusLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String warrantyHealthLabel(WarrantyHealth health) {
    return switch (health) {
      WarrantyHealth.none => _isRussian
          ? '\u0413\u0430\u0440\u0430\u043d\u0442\u0438\u044f \u043d\u0435 \u0443\u043a\u0430\u0437\u0430\u043d\u0430'
          : 'No warranty',
      WarrantyHealth.expired => _isRussian
          ? '\u0413\u0430\u0440\u0430\u043d\u0442\u0438\u044f \u0438\u0441\u0442\u0435\u043a\u043b\u0430'
          : 'Warranty expired',
      WarrantyHealth.expiring => _isRussian
          ? '\u0421\u043a\u043e\u0440\u043e \u0437\u0430\u043a\u0430\u043d\u0447\u0438\u0432\u0430\u0435\u0442\u0441\u044f'
          : 'Expiring soon',
      WarrantyHealth.protected => _isRussian
          ? '\u0413\u0430\u0440\u0430\u043d\u0442\u0438\u044f \u0434\u0435\u0439\u0441\u0442\u0432\u0443\u0435\u0442'
          : 'Warranty active',
    };
  }
}
