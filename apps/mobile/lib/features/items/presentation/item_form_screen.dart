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

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pickPurchaseDate() async {
    final date = await _pickDate(_purchaseDate);
    if (date != null) {
      setState(() => _purchaseDate = date);
    }
  }

  Future<void> _pickWarrantyDate() async {
    final date = await _pickDate(_warrantyDate ?? DateTime.now().add(const Duration(days: 365)));
    if (date != null) {
      setState(() => _warrantyDate = date);
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
        location: _optional(_locationController.text),
        serialNumber: _optional(_serialController.text),
        purchaseDate: _purchaseDate,
        warrantyExpiresAt: _warrantyDate,
        notes: _optional(_notesController.text),
      );
      if (_isEditing) {
        await ref.read(itemListControllerProvider.notifier).updateItem(item);
      } else {
        await ref.read(itemListControllerProvider.notifier).add(item);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? context.l10n.itemUpdated : context.l10n.itemSaved)),
      );
      Navigator.of(context).pop(item);
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

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final purchaseText = _purchaseDate == null
        ? l10n.purchaseDate
        : '${l10n.purchaseDate}: ${MaterialLocalizations.of(context).formatMediumDate(_purchaseDate!)}';
    final warrantyText = _warrantyDate == null
        ? l10n.warrantyUntil
        : '${l10n.warrantyUntil}: ${MaterialLocalizations.of(context).formatMediumDate(_warrantyDate!)}';

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
                decoration: InputDecoration(labelText: l10n.fieldCategory),
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
                decoration: InputDecoration(labelText: l10n.serialNumber),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickPurchaseDate,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(purchaseText),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickWarrantyDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(warrantyText),
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
}
