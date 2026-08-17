import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.complaint(ComplaintStatus status, {Key? key}) {
    return StatusBadge(
      key: key,
      label: status.label,
      color: _complaintColor(status),
      icon: _complaintIcon(status),
    );
  }

  factory StatusBadge.vendor(VendorStatus status, {Key? key}) {
    return StatusBadge(
      key: key,
      label: status.label,
      color: _vendorColor(status),
      icon: _vendorIcon(status),
    );
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _complaintColor(ComplaintStatus status) => switch (status) {
    ComplaintStatus.submitted => AppColors.info,
    ComplaintStatus.underReview => AppColors.warning,
    ComplaintStatus.assigned => AppColors.animals,
    ComplaintStatus.inProgress => AppColors.primary,
    ComplaintStatus.resolved => AppColors.success,
    ComplaintStatus.rejected => AppColors.error,
    ComplaintStatus.moreInformationRequired => AppColors.roads,
  };

  static IconData _complaintIcon(ComplaintStatus status) => switch (status) {
    ComplaintStatus.submitted => Icons.check_circle_outline_rounded,
    ComplaintStatus.underReview => Icons.manage_search_rounded,
    ComplaintStatus.assigned => Icons.person_pin_circle_outlined,
    ComplaintStatus.inProgress => Icons.construction_rounded,
    ComplaintStatus.resolved => Icons.task_alt_rounded,
    ComplaintStatus.rejected => Icons.cancel_outlined,
    ComplaintStatus.moreInformationRequired => Icons.help_outline_rounded,
  };

  static Color _vendorColor(VendorStatus status) => switch (status) {
    VendorStatus.submitted => AppColors.info,
    VendorStatus.documentsVerified => AppColors.secondary,
    VendorStatus.underReview => AppColors.warning,
    VendorStatus.locationAssessment => AppColors.animals,
    VendorStatus.approved => AppColors.success,
    VendorStatus.changesRequired => AppColors.roads,
    VendorStatus.rejected => AppColors.error,
    VendorStatus.permissionIssued => AppColors.success,
  };

  static IconData _vendorIcon(VendorStatus status) => switch (status) {
    VendorStatus.submitted => Icons.check_circle_outline_rounded,
    VendorStatus.documentsVerified => Icons.fact_check_outlined,
    VendorStatus.underReview => Icons.manage_search_rounded,
    VendorStatus.locationAssessment => Icons.location_searching_rounded,
    VendorStatus.approved => Icons.verified_outlined,
    VendorStatus.changesRequired => Icons.edit_note_rounded,
    VendorStatus.rejected => Icons.cancel_outlined,
    VendorStatus.permissionIssued => Icons.workspace_premium_outlined,
  };
}
