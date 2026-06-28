import '../../../core/localization/app_localizations.dart';

extension MaintenanceLocalizations on AppLocalizations {
  bool get _isRussian => languageCode == 'ru';

  String get maintenance => _isRussian ? 'Обслуживание' : 'Maintenance';
  String get maintenanceHistory => _isRussian ? 'История обслуживания' : 'Maintenance history';
  String get addMaintenance => _isRussian ? 'Добавить задачу' : 'Add task';
  String get editMaintenance => _isRussian ? 'Редактировать задачу' : 'Edit task';
  String get taskTitle => _isRussian ? 'Что нужно сделать' : 'Task title';
  String get selectItem => _isRussian ? 'Вещь' : 'Item';
  String get frequencyDays => _isRussian ? 'Периодичность, дней' : 'Frequency, days';
  String get nextDueDate => _isRussian ? 'Следующее обслуживание' : 'Next due date';
  String get taskSaved => _isRussian ? 'Задача добавлена' : 'Task added';
  String get taskUpdated => _isRussian ? 'Изменения сохранены' : 'Changes saved';
  String get noItemsForTaskTitle => _isRussian ? 'Сначала добавьте вещь' : 'Add an item first';
  String get noItemsForTaskBody => _isRussian
      ? 'Задача обслуживания всегда привязана к вещи из вашего инвентаря.'
      : 'A maintenance task must be linked to an inventory item.';
  String get markComplete => _isRussian ? 'Отметить выполненным' : 'Mark complete';
  String get taskCompleted => _isRussian
      ? 'Задача выполнена. Следующая дата обновлена.'
      : 'Task completed. The next due date was updated.';
  String get noMaintenanceTitle => _isRussian ? 'Нет задач по обслуживанию' : 'No maintenance tasks';
  String get noMaintenanceBody => _isRussian
      ? 'Добавьте задачу к вещи, чтобы не забывать о регулярном уходе.'
      : 'Add a task to an item so regular care is never forgotten.';
  String get noMaintenanceForItem => _isRussian
      ? 'Для этой вещи пока нет задач обслуживания.'
      : 'There are no maintenance tasks for this item yet.';
  String get noMaintenanceHistoryTitle => _isRussian ? 'История пока пуста' : 'No completed maintenance yet';
  String get noMaintenanceHistoryBody => _isRussian
      ? 'После выполнения задачи здесь появится запись с датой и вещью.'
      : 'Completed tasks will appear here with their date and linked item.';
  String get dueToday => _isRussian ? 'Нужно выполнить сегодня' : 'Due today';

  String itemContext(String itemName) => _isRussian ? 'Вещь: $itemName' : 'Item: $itemName';
  String completedAt(String timestamp) => _isRussian ? 'Выполнено: $timestamp' : 'Completed: $timestamp';
  String dueInDays(int days) => _isRussian ? 'Через $days дн.' : 'Due in $days days';
  String overdueBy(int days) => _isRussian ? 'Просрочено на $days дн.' : '$days days overdue';
}
