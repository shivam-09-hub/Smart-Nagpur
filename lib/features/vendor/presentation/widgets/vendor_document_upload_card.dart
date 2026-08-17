import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';

import 'vendor_widgets.dart';

/// Reusable, service-agnostic document row for the vendor application and
/// document-vault surfaces. File selection is delegated to the caller so the
/// widget remains testable and independent of a platform picker.
class VendorDocumentUploadCard extends StatelessWidget {
  const VendorDocumentUploadCard({
    required this.type,
    required this.label,
    required this.requirement,
    required this.onPick,
    super.key,
    this.document,
    this.onRemove,
    this.isBusy = false,
    this.supportingText,
  });

  final String type;
  final String label;
  final DocumentRequirement requirement;
  final VendorDocument? document;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  final bool isBusy;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final selected = document != null;
    return Semantics(
      container: true,
      label:
          '$label, ${documentRequirementLabel(requirement)}, ${selected ? 'selected' : 'not selected'}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.successSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.success : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.success.withValues(alpha: 0.13)
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.description_outlined,
                    color: selected ? AppColors.success : AppColors.vendor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.label),
                      const SizedBox(height: AppSpacing.xxs),
                      _RequirementBadge(requirement: requirement),
                    ],
                  ),
                ),
              ],
            ),
            if (supportingText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(supportingText!, style: AppTypography.caption),
            ],
            if (selected) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      vendorFileName(document!.path),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onPick,
                    icon: isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            selected
                                ? Icons.swap_horiz_rounded
                                : Icons.upload_file_rounded,
                          ),
                    label: Text(selected ? 'Replace' : 'Choose file'),
                  ),
                ),
                if (selected && onRemove != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.outlined(
                    tooltip: 'Remove $label',
                    onPressed: isBusy ? null : onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String documentRequirementLabel(DocumentRequirement requirement) =>
    switch (requirement) {
      DocumentRequirement.required => 'Required for this application',
      DocumentRequirement.optional => 'Optional',
      DocumentRequirement.conditional => 'Conditional',
    };

class _RequirementBadge extends StatelessWidget {
  const _RequirementBadge({required this.requirement});

  final DocumentRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (requirement) {
      DocumentRequirement.required => ('Required', AppColors.error),
      DocumentRequirement.optional => ('Optional', AppColors.textSecondary),
      DocumentRequirement.conditional => ('Conditional', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
