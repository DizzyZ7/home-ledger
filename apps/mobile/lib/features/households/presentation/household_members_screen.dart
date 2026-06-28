import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/household_repository.dart';
import '../domain/household_member.dart';
import '../domain/household_summary.dart';
import 'current_household_provider.dart';
import 'household_invites_section.dart';
import 'household_localizations.dart';

class HouseholdMembersScreen extends ConsumerStatefulWidget {
  const HouseholdMembersScreen({super.key});

  @override
  ConsumerState<HouseholdMembersScreen> createState() => _HouseholdMembersScreenState();
}

class _HouseholdMembersScreenState extends ConsumerState<HouseholdMembersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _removingUserId;
  var _adding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!(_formKey.currentState?.validate() ?? false) || _adding) return;
    setState(() => _adding = true);
    try {
      await ref.read(householdRepositoryProvider).addMember(_emailController.text.trim());
      _emailController.clear();
      ref.invalidate(currentHouseholdProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.householdMemberAdded)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeMember(HouseholdMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.removeMemberConfirmTitle),
        content: Text(dialogContext.removeMemberConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.removeHouseholdMember),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingUserId = member.userId);
    try {
      await ref.read(householdRepositoryProvider).removeMember(member.userId);
      ref.invalidate(currentHouseholdProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.householdMemberRemoved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _removingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(currentHouseholdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.householdMembersTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MembersErrorState(
          onRetry: () => ref.invalidate(currentHouseholdProvider),
        ),
        data: (household) {
          final isOwner = household.summary.role == HouseholdRole.owner;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(household.summary.name),
                  subtitle: Text(context.householdRole(household.summary.role)),
                ),
              ),
              const SizedBox(height: 16),
              if (isOwner)
                _AddMemberForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  adding: _adding,
                  onAdd: _addMember,
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.householdMembersReadOnly)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(context.householdMembersTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final member in household.members) ...[
                _HouseholdMemberTile(
                  member: member,
                  canRemove: isOwner && member.role != HouseholdRole.owner,
                  removing: _removingUserId == member.userId,
                  onRemove: () => _removeMember(member),
                ),
                const SizedBox(height: 8),
              ],
              if (isOwner) ...[
                const SizedBox(height: 12),
                const HouseholdInvitesSection(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AddMemberForm extends StatelessWidget {
  const _AddMemberForm({
    required this.formKey,
    required this.emailController,
    required this.adding,
    required this.onAdd,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool adding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.addHouseholdMember, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('household-member-email'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: context.memberEmailHint,
                  prefixIcon: const Icon(Icons.alternate_email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l10n.requiredField;
                  if (!email.contains('@')) return context.memberEmailHint;
                  return null;
                },
                onFieldSubmitted: (_) => onAdd(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('household-add-member'),
                  onPressed: adding ? null : onAdd,
                  icon: adding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(context.addHouseholdMember),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseholdMemberTile extends StatelessWidget {
  const _HouseholdMemberTile({
    required this.member,
    required this.canRemove,
    required this.removing,
    required this.onRemove,
  });

  final HouseholdMember member;
  final bool canRemove;
  final bool removing;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final initials = member.displayName.isEmpty ? '?' : member.displayName.substring(0, 1).toUpperCase();
    return Card(
      child: ListTile(
        key: ValueKey('household-member-${member.userId}'),
        leading: CircleAvatar(child: Text(initials)),
        title: Text(member.displayName),
        subtitle: Text('${member.email} · ${context.householdRole(member.role)}'),
        trailing: canRemove
            ? IconButton(
                key: ValueKey('household-remove-member-${member.userId}'),
                tooltip: context.removeHouseholdMember,
                onPressed: removing ? null : onRemove,
                icon: removing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_remove_outlined),
              )
            : null,
      ),
    );
  }
}

class _MembersErrorState extends StatelessWidget {
  const _MembersErrorState({required this.onRetry});

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
