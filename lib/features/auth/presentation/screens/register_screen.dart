import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_nagpur/data/data.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import '../auth_copy.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.controller,
    required this.onRegistered,
    required this.onConfirmationRequired,
    required this.onLogin,
  });

  final AppController controller;
  final VoidCallback onRegistered;
  final VoidCallback onConfirmationRequired;
  final VoidCallback onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return AuthCopy.requiredField;
    if (name.length < 2) return 'Enter your full name.';
    if (!RegExp(
      r"^[a-zA-Z\u0900-\u097F][a-zA-Z\u0900-\u097F .'-]*$",
    ).hasMatch(name)) {
      return 'Use letters and standard name punctuation only.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return AuthCopy.requiredField;
    if (digits.length != 10 || RegExp(r'^[0-5]').hasMatch(digits)) {
      return AuthCopy.invalidMobile;
    }
    return null;
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
    final password = value ?? '';
    if (password.isEmpty) return AuthCopy.requiredField;
    if (password.length < 8) return AuthCopy.shortPassword;
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) return AuthCopy.requiredField;
    if (value != _passwordController.text) return AuthCopy.passwordMismatch;
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _errorMessage = null;
      _showTermsError = !_acceptedTerms;
    });
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid || !_acceptedTerms) return;

    setState(() => _isSubmitting = true);
    try {
      final status = await widget.controller.register(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      switch (status) {
        case RegistrationStatus.authenticated:
          TextInput.finishAutofillContext();
          widget.onRegistered();
        case RegistrationStatus.confirmationRequired:
          TextInput.finishAutofillContext();
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your email to confirm it, then sign in.',
              ),
            ),
          );
          widget.onConfirmationRequired();
        case RegistrationStatus.failed:
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

  void _showLegalInformation() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account terms & privacy',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              const Text(
                'When you create an account, authentication is handled securely by Supabase and your profile and civic data may be stored in the configured cloud service. '
                'Demo mode remains separate and does not create a cloud account. Smart Nagpur is not yet an official municipal submission channel.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      title: AuthCopy.joinSmartNagpur,
      subtitle: AuthCopy.registerSubtitle,
      onBack: widget.onLogin,
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
                controller: _nameController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: AuthCopy.fullName,
                  hintText: AuthCopy.fullNameHint,
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _phoneController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: AuthCopy.mobileNumber,
                  hintText: AuthCopy.mobileHint,
                  prefixIcon: Icon(Icons.phone_android_rounded),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: AuthCopy.email,
                  hintText: AuthCopy.emailHint,
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                enabled: !_isSubmitting,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: AuthCopy.password,
                  helperText: 'At least 8 characters with a letter and number',
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
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _confirmController,
                enabled: !_isSubmitting,
                obscureText: _obscureConfirmation,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: AuthCopy.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                    tooltip: _obscureConfirmation
                        ? 'Show password'
                        : 'Hide password',
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
              const SizedBox(height: 12),
              Material(
                color: _showTermsError
                    ? scheme.errorContainer.withValues(alpha: .55)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() {
                          _acceptedTerms = !_acceptedTerms;
                          _showTermsError = false;
                        }),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(() {
                                  _acceptedTerms = value ?? false;
                                  _showTermsError = false;
                                }),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 11, right: 8),
                            child: Text(
                              '${AuthCopy.termsPrefix}${AuthCopy.terms}${AuthCopy.and}${AuthCopy.privacy}.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showTermsError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 5),
                  child: Text(
                    AuthCopy.acceptTerms,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _showLegalInformation,
                  child: const Text('Read terms and privacy information'),
                ),
              ),
              const SizedBox(height: 12),
              AuthSubmitButton(
                label: AuthCopy.register,
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.person_add_alt_1_rounded,
              ),
              const SizedBox(height: 20),
              AuthFooterAction(
                prompt: AuthCopy.haveAccount,
                actionLabel: AuthCopy.login,
                onPressed: widget.onLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
