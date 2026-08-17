import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import '../auth_copy.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.onAuthenticated,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onPasswordRecovery,
  });

  final AppController controller;
  final VoidCallback onAuthenticated;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final VoidCallback onPasswordRecovery;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isDemoSubmitting = false;
  String? _errorMessage;
  bool _recoveryNavigationScheduled = false;
  bool _authenticationNavigationScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePasswordRecovery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePasswordRecovery();
    });
  }

  void _handlePasswordRecovery() {
    if (!mounted) return;
    if (widget.controller.isPasswordRecovery && !_recoveryNavigationScheduled) {
      _recoveryNavigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPasswordRecovery();
      });
      return;
    }
    if (!_isSubmitting &&
        !_isDemoSubmitting &&
        !_authenticationNavigationScheduled &&
        widget.controller.isAuthenticated &&
        !widget.controller.isBusy &&
        widget.controller.profile != null) {
      _authenticationNavigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthenticated();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePasswordRecovery);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return AuthCopy.requiredField;
    if (value!.length < 8) return AuthCopy.shortPassword;
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.controller.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (success) {
        TextInput.finishAutofillContext();
        widget.onAuthenticated();
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

  Future<void> _useDemoAccess() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _errorMessage = null;
      _isDemoSubmitting = true;
    });
    try {
      await widget.controller.continueInDemoMode();
      if (!mounted) return;
      widget.onAuthenticated();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDemoSubmitting = false;
        _errorMessage = widget.controller.error ?? AuthCopy.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = _isSubmitting || _isDemoSubmitting;

    return AuthScaffold(
      title: AuthCopy.welcomeBack,
      subtitle: AuthCopy.loginSubtitle,
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
                AuthErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [LengthLimitingTextInputFormatter(254)],
                decoration: const InputDecoration(
                  labelText: AuthCopy.email,
                  hintText: AuthCopy.emailHint,
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !busy,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: AuthCopy.password,
                  hintText: AuthCopy.passwordHint,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : widget.onForgotPassword,
                  child: const Text(AuthCopy.forgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              AuthSubmitButton(
                label: AuthCopy.signIn,
                isLoading: _isSubmitting,
                onPressed: busy ? null : _submit,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _useDemoAccess,
                  icon: _isDemoSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.explore_outlined),
                  label: const Text(AuthCopy.demoAccess),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                AuthCopy.demoDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              AuthFooterAction(
                prompt: AuthCopy.noAccount,
                actionLabel: AuthCopy.createAccount,
                onPressed: widget.onRegister,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AuthCopy.privacyNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
