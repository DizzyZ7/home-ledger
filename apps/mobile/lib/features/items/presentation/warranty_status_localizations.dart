import '../../../core/localization/app_localizations.dart';
import '../domain/warranty_health.dart';

extension WarrantyStatusLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String warrantyHealthLabel(WarrantyHealth health) {
    return switch (health) {
      WarrantyHealth.none => _isRussian ? 'Гарантия не указана' : 'No warranty',
      WarrantyHealt.expired => _isRussian ? 'Гарантия истекла' : 'Warranty expired',
      WarrantyHealth.expiring => _isRussian ? 'Скоро заканчивается' : 'Expiring soon',
      WarrantyHealth.protected => _isRussian ? 'Гарантия действуетp�' : 'Warranty active',
    };
  }
}
