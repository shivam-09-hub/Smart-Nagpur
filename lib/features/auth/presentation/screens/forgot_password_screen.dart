import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import '../auth_copy.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.controller,
    required this.onLogin,
    required this.onPasswordRecovery,
  });

  final AppController controller;
  final VoidCallback onLogin;
  final VoidCallback onPasswordRecovery;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _resetRequested = false;
  String? _submittedEmail;
  String? _errorMessage;
  bool _recoveryNavigationScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePasswordRecovery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePasswordRecovery();
    });
  }

  void _handlePasswordRecovery() {
    if (!mounted ||
        _recoveryNavigationScheduled ||
        !widget.controller.isPasswordRecovery) {
      return;
    }
    _recoveryNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPasswordRecovery();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePasswordRecovery);
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return AuthCopy.requiredField;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return AuthCopy.invalidEmail;
    }
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      final success = await widget.controller.sendPasswordReset(email);
      if (!mounted) return;
      if (success) {
        TextInput.finishAutofillContext();
        setState(() {
          _isSubmitting = false;
          _resetRequested = true;
          _submittedEmail = email;
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = widget.controller.error ?? AuthCopy.genericError;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = widget.controller.error ?? AuthCopy.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: _resetRequested ? AuthCopy.resetRequested : AuthCopy.resetPassword,
      subtitle: _resetRequested
          ? AuthCopy.resetRequestedMessage
          : AuthCopy.resetSubtitle,
      onBack: widget.onLogin,
      child: _resetRequested ? _buildSuccess(context) : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      onChanged: () {
        if (_errorMessage != null) setState(() => _errorMessage = null);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_read_outlined, color: scheme.secondary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Supabase will send a password reset link when the address belongs to an account.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (_errorMessage != null) ...[
            AuthErrorBanner(
              message: _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 18),
          ],
          TextFormField(
            controller: _emailController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            inputFormatters: [LengthLimitingTextInputFormatter(254)],
            decoration: const InputDecoration(
              labelText: AuthCopy.email,
              hintText: AuthCopy.emailHint,
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: _validateEmail,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: AuthCopy.sendCode,
            onPressed: _submit,
            isLoading: _isSubmitting,
            icon: Icons.send_rounded,
          ),
          const SizedBox(height: 22),
          AuthFooterAction(
            prompt: AuthCopy.rememberPassword,
            actionLabel: AuthCopy.login,
            onPressed: widget.onLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: .58),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.mark_email_read_rounded,
                  color: scheme.primary,
                  size: 46,
                ),
                const SizedBox(height: 14),
                Text(
                  _submittedEmail ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'For privacy, we cannot confirm whether an account exists for this address.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: AuthCopy.returnToLogin,
            onPressed: widget.onLogin,
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}
