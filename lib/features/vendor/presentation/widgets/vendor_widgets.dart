import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';

class VendorDemoBanner extends StatelessWidget {
  const VendorDemoBanner({super.key, this.isDemo = true, this.message});

  final bool isDemo;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final resolvedMessage =
        message ??
        (isDemo
            ? 'Demo information stays on this device and is not sent to Nagpur Municipal Corporation.'
            : 'Application data is stored in your private cloud account. This development service is not connected to Nagpur Municipal Corporation.');
    return Semantics(
      container: true,
      label: resolvedMessage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.infoSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.science_outlined, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDemo ? 'DEMO MODE' : 'DEVELOPMENT SERVICE',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(resolvedMessage, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorResponsiveBody extends StatelessWidget {
  const VendorResponsiveBody({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.page,
      AppSpacing.md,
      AppSpacing.page,
      AppSpacing.xxl,
    ),
    this.maxWidth = 760,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class VendorStatusChip extends StatelessWidget {
  const VendorStatusChip({required this.status, super.key});

  final VendorStatus status;

  @override
  Widget build(BuildContext context) {
    final color = vendorStatusColor(status);
    return Semantics(
      label: 'Status: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          status.label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Color vendorStatusColor(VendorStatus status) => switch (status) {
  VendorStatus.approved || VendorStatus.permissionIssued => AppColors.success,
  VendorStatus.rejected => AppColors.error,
  VendorStatus.changesRequired => AppColors.warning,
  VendorStatus.submitted ||
  VendorStatus.documentsVerified ||
  VendorStatus.underReview ||
  VendorStatus.locationAssessment => AppColors.info,
};

class VendorSectionCard extends StatelessWidget {
  const VendorSectionCard({
    required this.title,
    required this.children,
    super.key,
    this.icon,
    this.onEdit,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;
  final VoidCallback? onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 21, color: AppColors.vendor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(child: Text(title, style: AppTypography.title)),
                ?trailing,
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}

class VendorInfoRow extends StatelessWidget {
  const VendorInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
          ],
          SizedBox(
            width: 126,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SelectableText(
              value.isEmpty ? 'Not provided' : value,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String vendorFormatDate(DateTime date) =>
    DateFormat('d MMM yyyy, h:mm a').format(date);

String vendorFileName(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isEmpty || parts.last.isEmpty ? 'Selected document' : parts.last;
}
