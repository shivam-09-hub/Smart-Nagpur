import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth_copy.dart';
import '../widgets/auth_scaffold.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.destination,
    required this.onVerified,
    required this.onEdit,
  });

  /// Mobile number or email entered on the preceding screen.
  final String destination;
  final VoidCallback onVerified;
  final VoidCallback onEdit;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  int _secondsUntilResend = 0;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String get _maskedDestination {
    final value = widget.destination.trim();
    if (value.contains('@')) {
      final parts = value.split('@');
      final local = parts.first;
      final visible = local.isEmpty
          ? ''
          : local.length <= 2
          ? local.substring(0, 1)
          : local.substring(0, 2);
      final hiddenCount = (local.length - visible.length).clamp(2, 8).toInt();
      final hidden = List.filled(hiddenCount, '•').join();
      return '$visible$hidden@${parts.skip(1).join('@')}';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return '••••••${digits.substring(digits.length - 4)}';
    }
    return value;
  }

  String? _validateCode(String? value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value ?? '')) {
      return AuthCopy.invalidCode;
    }
    return null;
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isVerifying = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) widget.onVerified();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = AuthCopy.genericError;
      });
    }
  }

  void _resend() {
    if (_secondsUntilResend > 0) return;
    _codeController.clear();
    setState(() {
      _errorMessage = null;
      _secondsUntilResend = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsUntilResend <= 1) {
        timer.cancel();
        setState(() => _secondsUntilResend = 0);
      } else {
        setState(() => _secondsUntilResend--);
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Demo code refreshed. Enter any 6-digit code to continue.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AuthScaffold(
      title: AuthCopy.verifyTitle,
      subtitle: 'Continue verification for $_maskedDestination.',
      onBack: widget.onEdit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text(AuthCopy.demoVerification)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              AuthErrorBanner(message: _errorMessage!),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _codeController,
              enabled: !_isVerifying,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 12,
                fontWeight: FontWeight.w700,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: AuthCopy.verifyCode,
                hintText: '000000',
                counterText: '',
              ),
              maxLength: 6,
              validator: _validateCode,
              onFieldSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: AuthCopy.verify,
              onPressed: _verify,
              isLoading: _isVerifying,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(AuthCopy.didntReceive),
                TextButton(
                  onPressed: _secondsUntilResend == 0 && !_isVerifying
                      ? _resend
                      : null,
                  child: Text(
                    _secondsUntilResend == 0
                        ? AuthCopy.resend
                        : 'Resend in ${_secondsUntilResend}s',
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _isVerifying ? null : widget.onEdit,
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: const Text(AuthCopy.changeDetails),
            ),
          ],
        ),
      ),
    );
  }
}
