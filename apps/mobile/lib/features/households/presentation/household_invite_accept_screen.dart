import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../data/household_repository.dart';
import 'current_household_provider.dart';
import 'household_controller.dart';
import 'household_localizations.dart';

class HouseholdInviteAcceptScreen extends ConsumerStatefulWidget {
  const HouseholdInviteAcceptScreen({super.key});

  @override
  ConsumerState<HouseholdInviteAcceptScreen> createState() => _HouseholdInviteAcceptScreenState();
}

class _HouseholdInviteAcceptScreenState extends ConsumerState<HouseholdInviteAcceptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  var _accepting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_accepting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _accepting = true);
    try {
      await ref.read(householdRepositoryProvider).acceptInvite(_codeController.text.trim());
      ref.invalidate(householdControllerProvider);
      ref.invalidate(currentHouseholdProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.invitationAccepted)),
      );
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _accepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(context.joinHousehold)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.group_add_outlined, size: 36),
                    const SizedBox(height: 16),
                    Text(context.joinHousehold, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(context.invitationCodeHint),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('household-invite-code'),
                      controller: _codeController,
                      autofocus: true,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: context.invitationCode,
                        prefixIcon: const Icon(Icons.key_outlined),
                      ),
                      validator: (value) {
                        if ((value?.trim().length ?? 0) < 4) {
                          return l10n.requiredField;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _accept(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('household-accept-invite'),
                        onPressed: _accepting ? null : _accept,
                        icon: _accepting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.group_add_outlined),
                        label: Text(context.joinHousehold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
