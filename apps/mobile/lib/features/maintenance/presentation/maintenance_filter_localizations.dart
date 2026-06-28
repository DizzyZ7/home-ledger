import '../../../core/localization/app_localizations.dart';
import 'maintenance_filter.dart';

extension MaintenanceFilterLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String maintenanceFilterLabel(MaintenanceFilter filter) {
    return switch (filter) {
      MaintenanceFilter.all => _isRussian ? 'Все' : 'All',
      MaintenanceFilter.overdue => _isRussian ? 'Просроченные' : 'Overdue',
      MaintenanceFilter.upcoming => _isRussian ? 'Ближайшие' : 'Upcoming',
    };
  }

  String get noOverdueMaintenance => _isRussian ? 'Нет просроченных задач' : 'No overdue tasks';
  String get noUpcomingMaintenance => _isRussian ? 'Нет задач на ближайшие 30 дней' : 'No tasks in the next 30 days';
  String get maintenanceFiltersHint => _isRussian
      ? 'Фильтры применяются к уже загруженным задачам.'
      : 'Filters apply to tasks already loaded on this device.';
}
