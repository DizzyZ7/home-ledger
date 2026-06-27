import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../domain/home_item.dart';
import 'item_localizations.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({this.item, super.key});

  final HomeItem? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'appliance';
  DateTime? _purchaseDate;
  DateTime? _warrantyDate;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) {
      return;
    }
    _nameController.text = item.name;
    _locationController.text = item.location ?? '';
    _serialController.text = item.serialNumber ?? '';
    _notesController.text = item.notes ?? '';
    _category = item.category;
    _purchaseDate = item.purchaseDate;
    _warrantyDate = item.warrantyExpiresAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _serialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => onChanged(date));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final item = HomeItem(
        id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        category: _category,
        location: _optionalValue(_locationController.text),
        serialNumber: _optionalValue(_serialController.text),
        purchaseDate: _purchaseDate,
        warrantyExpiresAt: _warrantyDate,
        notes: _optionalValue(_notesController.text),
      );
      final controller = ref.read(itemListControllerProvider.notifier);
      if (_isEditing) {
        await controller.update(item);
      } else {
        await controller.add(item);
      }
      if (!mounted) {
        return;
      }
      final message = _isEditing ? context.l10n.itemUpdated : context.l10n.itemSaved;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final purchaseText = _dateButtonText(l10n.purchaseDate, _purchaseDate);
    final warrantyText = _dateButtonText(l10n.warrantyUntil, _warrantyDate);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editItem : l10n.addItem)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.itemName),
                validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.category),
                items: const [
                  DropdownMenuItem(value: 'appliance', child: Text('Appliance')),
                  DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                  DropdownMenuItem(value: 'tool', child: Text('Tool')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _category = value ?? 'other'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.location),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l10n.serialNumber),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: purchaseText,
                hasValue: _purchaseDate != null,
                onPick: () => _pickDate(
                  value: _purchaseDate,
                  onChanged: (date) => _purchaseDate = date,
                ),
                onClear: () => setState(() => _purchaseDate = null),
              ),
              const SizedBox(height: 12),
              _DateField(
                label: warrantyText,
                hasValue: _warrantyDate != null,
                onPick: () => _pickDate(
                  value: _warrantyDate,
                  onChanged: (date) => _warrantyDate = date,
                ),
                onClear: () => setState(() => _warrantyDate = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.notes),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
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

  String _dateButtonText(String label, DateTime? date) {
    if (date == null) {
      return label;
    }
    return '$label: ${MaterialLocalizations.of(context).formatMediumDate(date)}';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hasValue,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.event_outlined),
            label: Text(label),
          ),
        ),
        if (hasValue) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: onClear,
            icon: const Icon(Icons.clear),
          ),
        ],
      ],
    );
  }
}
