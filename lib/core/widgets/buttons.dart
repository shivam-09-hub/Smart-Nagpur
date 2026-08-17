import 'package:flutter/material.dart';

import '../theme/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final child = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: backgroundColor == null
          ? null
          : ElevatedButton.styleFrom(backgroundColor: backgroundColor),
      child: isLoading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.onPrimary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final child = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: foregroundColor == null
          ? null
          : OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(color: foregroundColor!),
            ),
      child: isLoading
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foregroundColor ?? AppColors.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}
