import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/household_summary.dart';
import 'household_controller.dart';
import 'household_localizations.dart';

class HouseholdSwitcherScreen extends ConsumerStatefulWidget {
  const HouseholdSwitcherScreen({super.key});

  @override
  ConsumerState<HouseholdSwitcherScreen> createState() => _HouseholdSwitcherScreenState();
}

class _HouseholdSwitcherScreenState extends ConsumerState<HouseholdSwitcherScreen> {
  String? _selectingId;
  var _savingName = false;

  Future<void> _select(HouseholdSummary household) async {
    if (household.isActive || _selectingId != null || _savingName) {
      return;
    }

    setState(() => _selectingId = household.id);
    try {
      await ref.read(householdControllerProvider.notifier).selectHousehold(household.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.householdSwitched)),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _selectingId = null);
      }
    }
  }

  Future<void> _createHousehold() async {
    final name = await _requestHouseholdName(title: context.createHousehold);
    if (name == null || !mounted) {
      return;
    }

    setState(() => _savingName = true);
    try {
      await ref.read(householdControllerProvider.notifier).createHousehold(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.householdCreated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  Future<void> _renameHousehold(HouseholdSummary household) async {
    final name = await _requestHouseholdName(
      title: context.renameHousehold,
      initialValue: household.name,
    );
    if (name == null || !mounted) {
      return;
    }

    setState(() => _savingName = true);
    try {
      await ref.read(householdControllerProvider.notifier).renameCurrentHousehold(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.householdRenamed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  Future<String?> _requestHouseholdName({
    required String title,
    String? initialValue,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _HouseholdNameDialog(
        title: title,
        initialValue: initialValue,
      ),
    );
  }

  HouseholdSummary? _activeHousehold(List<HouseholdSummary> households) {
    for (final household in households) {
      if (household.isActive) {
        return household;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final households = ref.watch(householdControllerProvider);
    final activeHousehold = _activeHousehold(households.valueOrNull ?? const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.householdTitle),
        actions: [
          IconButton(
            key: const ValueKey('household-create-action'),
            tooltip: context.createHousehold,
            onPressed: _savingName ? null : _createHousehold,
            icon: const Icon(Icons.add_home_work_outlined),
          ),
          if (activeHousehold?.role == HouseholdRole.owner)
            IconButton(
              key: const ValueKey('household-rename-action'),
              tooltip: context.renameHousehold,
              onPressed: _savingName ? null : () => _renameHousehold(activeHousehold!),
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            key: const ValueKey('household-accept-invite-action'),
            tooltip: context.joinHousehold,
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => context.push('/households/join'),
          ),
          IconButton(
            key: const ValueKey('household-members-action'),
            tooltip: context.householdMembersTitle,
            icon: const Icon(Icons.group_outlined),
            onPressed: () => context.push('/households/members'),
          ),
        ],
      ),
      body: households.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _HouseholdErrorState(
          onRetry: () => ref.invalidate(householdControllerProvider),
        ),
        data: (data) {
          if (data.isEmpty) {
            return const _HouseholdEmptyState();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(context.householdSubtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              for (final household in data) ...[
                _HouseholdTile(
                  household: household,
                  selecting: _selectingId == household.id,
                  onTap: () => _select(household),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HouseholdNameDialog extends StatefulWidget {
  const _HouseholdNameDialog({
    required this.title,
    this.initialValue,
  });

  final String title;
  final String? initialValue;

  @override
  State<_HouseholdNameDialog> createState() => _HouseholdNameDialogState();
}

class _HouseholdNameDialogState extends State<_HouseholdNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey('household-name-input'),
          controller: _controller,
          autofocus: true,
          maxLength: 100,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.householdName,
            prefixIcon: const Icon(Icons.home_work_outlined),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return context.l10n.requiredField;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const _HouseholdTile({
    required this.household,
    required this.selecting,
    required this.onTap,
  });

  final HouseholdSummary household;
  final bool selecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = household.isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest;

    return Semantics(
      selected: household.isActive,
      button: !household.isActive,
      label: '${household.name}. ${context.householdRole(household.role)}',
      child: Card(
        color: selectedColor,
        child: ListTile(
          key: ValueKey('household-select-${household.id}'),
          enabled: !household.isActive && !selecting,
          leading: Icon(household.isActive ? Icons.home : Icons.home_outlined),
          title: Text(household.name),
          subtitle: Text(context.householdRole(household.role)),
          trailing: household.isActive
              ? Chip(label: Text(context.householdActive))
              : selecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _HouseholdEmptyState extends StatelessWidget {
  const _HouseholdEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined, size: 48),
            const SizedBox(height: 16),
            Text(context.noHouseholdsTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(context.noHouseholdsBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HouseholdErrorState extends StatelessWidget {
  const _HouseholdErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(context.l10n.errorGeneric, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
