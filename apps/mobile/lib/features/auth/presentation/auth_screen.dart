import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import 'session_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.showMockHint, super.key});

  final bool showMockHint;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _registering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = ref.read(sessionControllerProvider.notifier);
    if (_registering) {
      await controller.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
    } else {
      await controller.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final isLoading = session.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.l10n.appTitle, style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 12),
                    if (widget.showMockHint)
                      Semantics(
                        liveRegion: true,
                        child: Text(l10n.mockMode, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    if (widget.showMockHint) const SizedBox(height: 24),
                    if (_registering) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: l10n.displayName),
                        validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.email),
                      validator: (value) => value == null || !value.contains('@') ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(labelText: l10n.password),
                      validator: (value) => value == null || value.length < 12 ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 20),
                    if (session.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.errorGeneric,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_registering ? l10n.createAccount : l10n.signIn),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => setState(() {
                                _registering = !_registering;
                              }),
                      child: Text(_registering ? l10n.haveAccount : l10n.noAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
