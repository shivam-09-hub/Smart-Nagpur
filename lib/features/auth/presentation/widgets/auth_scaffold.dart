import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/app_tokens.dart';

import '../../../bootstrap/presentation/bootstrap_copy.dart';
import '../../../bootstrap/presentation/widgets/smart_nagpur_brand.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            final form = SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                wide ? AppSpacing.huge : AppSpacing.xl,
                wide ? 48 : 12,
                wide ? AppSpacing.huge : AppSpacing.xl,
                AppSpacing.xl + viewInsets.bottom,
              ),
              child: Align(
                alignment: wide ? Alignment.centerLeft : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!wide) ...[
                        _MobileHeader(onBack: onBack),
                        const SizedBox(height: 34),
                      ] else if (onBack != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: onBack,
                            tooltip: 'Back',
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 30),
                      child,
                    ],
                  ),
                ),
              ),
            );

            if (!wide) return form;
            return Row(
              children: [
                const Expanded(flex: 4, child: _AuthBrandPanel()),
                Expanded(flex: 6, child: form),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
        ],
        const Expanded(
          child: SmartNagpurBrand(compact: true, showTagline: false),
        ),
      ],
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .055),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmartNagpurBrand(light: true),
                const Spacer(),
                Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white.withValues(alpha: .9),
                  size: 54,
                ),
                const SizedBox(height: 24),
                Text(
                  'Your City.\nYour Voice.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  BootstrapCopy.cityServices,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: scheme.onErrorContainer,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  color: scheme.onErrorContainer,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        iconAlignment: IconAlignment.end,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class AuthFooterAction extends StatelessWidget {
  const AuthFooterAction({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
