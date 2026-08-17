import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import '../auth_copy.dart';
import '../widgets/auth_scaffold.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    required this.controller,
    required this.onCompleted,
    required this.onCancel,
    super.key,
  });

  final AppController controller;
  final VoidCallback onCompleted;
  final VoidCallback onCancel;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return AuthCopy.shortPassword;
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one letter and number.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) return AuthCopy.passwordMismatch;
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final success = await widget.controller.updateRecoveredPassword(
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      TextInput.finishAutofillContext();
      widget.onCompleted();
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = widget.controller.error ?? AuthCopy.genericError;
    });
  }

  Future<void> _cancel() async {
    if (_isSubmitting) return;
    await widget.controller.logout();
    if (mounted) widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a new password',
      subtitle: 'Your recovery link was verified securely by Supabase.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          onChanged: () {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                AuthErrorBanner(message: _errorMessage!),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _passwordController,
                enabled: !_isSubmitting,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 8 characters with a letter and number',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _confirmationController,
                enabled: !_isSubmitting,
                obscureText: _obscureConfirmation,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validateConfirmation,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              AuthSubmitButton(
                label: 'Update password',
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting ? null : _cancel,
                child: const Text('Cancel and return to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
