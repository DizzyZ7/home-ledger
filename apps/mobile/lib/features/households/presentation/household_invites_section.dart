import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../data/household_repository.dart';
import '../domain/household_invite.dart';
import 'household_invites_provider.dart';
import 'household_localizations.dart';

String _formatInvitationExpiry(MaterialLocalizations localizations, DateTime value) {
  final local = value.toLocal();
  return '${localizations.formatMediumDate(local)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class HouseholdInvitesSection extends ConsumerStatefulWidget {
  const HouseholdInvitesSection({super.key});

  @override
  ConsumerState<HouseholdInvitesSection> createState() => _HouseholdInvitesSectionState();
}

class _HouseholdInvitesSectionState extends ConsumerState<HouseholdInvitesSection> {
  var _creating = false;
  String? _revokingId;

  Future<void> _createInvite() async {
    if (_creating) {
      return;
    }
    setState(() => _creating = true);
    try {
      final created = await ref.read(householdRepositoryProvider).createInvite();
      ref.invalidate(householdInvitesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.invitationCodeCreated)),
      );
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _InviteCodeDialog(invite: created),
      );
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } on Object {
      if (mounted) {
        _showError(context.l10n.errorGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _revoke(HouseholdInvite invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.revokeInvitationTitle),
        content: Text(dialogContext.revokeInvitationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.revokeInvitation),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _revokingId = invite.id);
    try {
      await ref.read(householdRepositoryProvider).revokeInvite(invite.id);
      ref.invalidate(householdInvitesProvider);
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } on Object {
      if (mounted) {
        _showError(context.l10n.errorGeneric);
      }
    } finally {
      if (mounted) {
        setState(() => _revokingId = null);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final invites = ref.watch(householdInvitesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.invitationsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('household-create-invite'),
                  onPressed: _creating ? null : _createInvite,
                  icon: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.key_outlined),
                  label: Text(context.createInvitation),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.invitationCodeSecurityHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            invites.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.errorGeneric),
                  TextButton(
                    onPressed: () => ref.invalidate(householdInvitesProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Text(context.noActiveInvitations);
                }
                return Column(
                  children: [
                    for (final invite in data)
                      _InviteTile(
                        invite: invite,
                        revoking: _revokingId == invite.id,
                        onRevoke: () => _revoke(invite),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeDialog extends StatelessWidget {
  const _InviteCodeDialog({required this.invite});

  final CreatedHouseholdInvite invite;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(context.invitationCode),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            invite.code,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          Text('${context.invitationExpires}: ${_formatInvitationExpiry(localizations, invite.invite.expiresAt)}'),
          const SizedBox(height: 8),
          Text(context.invitationCodeSecurityHint),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: invite.code));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.invitationCodeCopied)),
              );
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: Text(context.l10n.languageCode == 'ru' ? 'Копировать' : 'Copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.continueLabel),
        ),
      ],
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.invite,
    required this.revoking,
    required this.onRevoke,
  });

  final HouseholdInvite invite;
  final bool revoking;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return ListTile(
      key: ValueKey('household-invite-${invite.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.key_outlined),
      title: Text(context.invitationExpires),
      subtitle: Text(_formatInvitationExpiry(localizations, invite.expiresAt)),
      trailing: revoking
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              key: ValueKey('household-revoke-invite-${invite.id}'),
              tooltip: context.revokeInvitation,
              icon: const Icon(Icons.key_off_outlined),
              onPressed: onRevoke,
            ),
    );
  }
}
