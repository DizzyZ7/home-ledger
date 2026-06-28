import '../../../core/localization/app_localizations.dart';

extension DashboardLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get maintenanceNeedsAttention => _isRussian ? 'Обслуживание требует внимания' : 'Maintenance needs attention';
  String get noWarrantyRisk => _isRussian ? 'Срочных гарантий нет' : 'No urgent warranties';
  String get noOverdueMaintenance => _isRussian ? 'Нет просроченных задач' : 'No overdue tasks';
  String get maintenanceLoading => _isRussian ? 'Проверяем обслуживание…' : 'Checking maintenance…';
  String get maintenanceUnavailable => _isRussian ? 'Не удалось загрузить обслуживание' : 'Maintenance could not be loaded';

  String warrantyRiskCount(int count) => _isRussian
      ? '$count ${_plural(count, one: 'гарантия требует', few: 'гарантии требуют', many: 'гарантий требуют')} внимания'
      : '$count ${count == 1 ? 'warranty needs' : 'warranties need'} attention';

  String overdueMaintenanceCount(int count) => _isRussian
      ? '$count ${_plural(count, one: 'просроченная задача', few: 'просроченные задачи', many: 'просроченных задач')}'
      : '$count ${count == 1 ? 'overdue task' : 'overdue tasks'}';

  String _plural(int value, {required String one, required String few, required String many}) {
    final remainder100 = value % 100;
    final remainder10 = value % 10;
    if (remainder100 >= 11 && remainder100 <= 14) {
      return many;
    }
    if (remainder10 == 1) {
      return one;
    }
    if (remainder10 >= 2 && remainder10 <= 4) {
      return few;
    }
    return many;
  }
}
