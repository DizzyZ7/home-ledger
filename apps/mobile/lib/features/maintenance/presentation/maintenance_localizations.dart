import '../../../core/localization/app_localizations.dart';

extension MaintenanceLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get maintenance => _isRussian ? 'Обслуживание' : 'Maintenance';
  String get markComplete => _isRussian ? 'Отметить выполненным' : 'Mark complete';
  String get taskCompleted => _isRussian
      ? 'Задача выполнена. Следующая дата обновлена.'
      : 'Task completed. The next due date was updated.';
  String get noMaintenanceTitle => _isRussian ? 'Нет задач по обслуживанию' : 'No maintenance tasks';
  String get noMaintenanceBody => _isRussian
      ? 'Добавьте задачу к вещи, чтобы не забывать о регулярном уходе.'
      : 'Add a task to an item so regular care is never forgotten.';
  String get dueToday => _isRussian ? 'Нужно выполнить сегодня' : 'Due today';

  String dueInDays(int days) => _isRussian ? 'Через $days дн.' : 'Due in $days days';
  String overdueBy(int days) => _isRussian ? 'Просрочено на $days дн.' : '$days days overdue';
}
