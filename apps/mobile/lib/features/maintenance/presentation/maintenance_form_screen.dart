import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../../items/domain/home_item.dart';
import '../domain/maintenance_task.dart';
import 'maintenance_list_controller.dart';
import 'maintenance_localizations.dart';

class MaintenanceFormScreen extends ConsumerStatefulWidget {
  const MaintenanceFormScreen({this.task, this.initialItem, super.key})
      : assert(task == null || initialItem == null);

  final MaintenanceTask? task;
  final HomeItem? initialItem;

  @override
  ConsumerState<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _frequencyController = TextEditingController(text: '90');
  final _notesController = TextEditingController();
  String? _itemId;
  DateTime _nextDueDate = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.task != null;
  bool get _itemLocked => _isEditing || widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task == null) {
      _itemId = widget.initialItem?.id;
      return;
    }
    _itemId = task.itemId;
    _titleController.text = task.title;
    _frequencyController.text = task.frequencyDays.toString();
    _notesController.text = task.notes ?? '';
    _nextDueDate = task.nextDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _nextDueDate = selected);
    }
  }

  Future<void> _save({String? fallbackItemId, String? selectedItemName}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final itemId = widget.task?.itemId ?? _itemId ?? fallbackItemId;
    if (itemId == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final task = MaintenanceTask(
        id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        itemId: itemId,
        itemName: widget.task?.itemName ?? selectedItemName,
        title: _titleController.text.trim(),
        notes: _optional(_notesController.text),
        frequencyDays: int.parse(_frequencyController.text.trim()),
        nextDueDate: _nextDueDate,
        completedAt: widget.task?.completedAt,
      );
      if (_isEditing) {
        await ref.read(maintenanceListControllerProvider.notifier).updateTask(task);
      } else {
        await ref.read(maintenanceListControllerProvider.notifier).createTask(task);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? context.l10n.taskUpdated : context.l10n.taskSaved)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemListControllerProvider);
    return items.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _MaintenanceFormError(onBack: () => Navigator.of(context).pop()),
      data: (data) {
        if (data.isEmpty && !_isEditing && widget.initialItem == null) {
          return const _NoItemsForMaintenance();
        }

        final selectedItemId = widget.task?.itemId ?? _itemId ?? data.first.id;
        var selectedItemName = widget.initialItem?.id == selectedItemId
            ? widget.initialItem!.name
            : selectedItemId;
        for (final item in data) {
          if (item.id == selectedItemId) {
            selectedItemName = item.name;
            break;
          }
        }

        return _MaintenanceTaskForm(
          formKey: _formKey,
          items: data,
          isEditing: _isEditing,
          itemLocked: _itemLocked,
          selectedItemId: selectedItemId,
          selectedItemName: selectedItemName,
          titleController: _titleController,
          frequencyController: _frequencyController,
          notesController: _notesController,
          nextDueDate: _nextDueDate,
          saving: _saving,
          onItemChanged: _itemLocked ? null : (value) => setState(() => _itemId = value),
          onPickDueDate: _pickDueDate,
          onSave: () => _save(
            fallbackItemId: data.isEmpty ? null : data.first.id,
            selectedItemName: selectedItemName,
          ),
        );
      },
    );
  }
}

class _MaintenanceTaskForm extends StatelessWidget {
  const _MaintenanceTaskForm({
    required this.formKey,
    required this.items,
    required this.isEditing,
    required this.itemLocked,
    required this.selectedItemId,
    required this.selectedItemName,
    required this.titleController,
    required this.frequencyController,
    required this.notesController,
    required this.nextDueDate,
    required this.saving,
    required this.onItemChanged,
    required this.onPickDueDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final List<HomeItem> items;
  final bool isEditing;
  final bool itemLocked;
  final String selectedItemId;
  final String selectedItemName;
  final TextEditingController titleController;
  final TextEditingController frequencyController;
  final TextEditingController notesController;
  final DateTime nextDueDate;
  final bool saving;
  final ValueChanged<String?>? onItemChanged;
  final VoidCallback onPickDueDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateText = '${l10n.nextDueDate}: ${MaterialLocalizations.of(context).formatMediumDate(nextDueDate)}';

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editMaintenance : l10n.addMaintenance)),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (itemLocked)
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.selectItem),
                  child: Text(selectedItemName),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedItemId),
                  initialValue: selectedItemId,
                  decoration: InputDecoration(labelText: l10n.selectItem),
                  items: items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onItemChanged,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.taskTitle),
                validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: frequencyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.frequencyDays),
                validator: (value) {
                  final days = int.tryParse(value?.trim() ?? '');
                  if (days == null || days < 1 || days > 3650) {
                    return l10n.errorGeneric;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onPickDueDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(dateText),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.notes),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoItemsForMaintenance extends StatelessWidget {
  const _NoItemsForMaintenance();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 16),
              Text(l10n.noItemsForTaskTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.noItemsForTaskBody, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceFormError extends StatelessWidget {
  const _MaintenanceFormError({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: OutlinedButton(
          onPressed: onBack,
          child: Text(context.l10n.cancel),
        ),
      ),
    );
  }
}
