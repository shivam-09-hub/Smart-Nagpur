import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../features/complaints/presentation/widgets/development_map.dart';
import '../theme/theme.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.requirement,
    required this.onPick,
    this.fileName,
    this.onRemove,
    this.supportingText,
  });

  final String title;
  final DocumentRequirement requirement;
  final VoidCallback onPick;
  final String? fileName;
  final VoidCallback? onRemove;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final requirementLabel = switch (requirement) {
      DocumentRequirement.required => 'Required',
      DocumentRequirement.optional => 'Optional',
      DocumentRequirement.conditional => 'Conditional',
    };
    final requirementColor = switch (requirement) {
      DocumentRequirement.required => AppColors.error,
      DocumentRequirement.optional => AppColors.textSecondary,
      DocumentRequirement.conditional => AppColors.warning,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.document, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: AppTypography.title)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: requirementColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    requirementLabel,
                    style: AppTypography.caption.copyWith(
                      color: requirementColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (supportingText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(supportingText!, style: AppTypography.bodySmall),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (fileName == null)
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Choose file'),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        fileName!,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        tooltip: 'Remove document',
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PhotoPreviewCard extends StatelessWidget {
  const PhotoPreviewCard({
    super.key,
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(
              File(path),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceMuted,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                      size: 36,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('Image preview unavailable'),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.xs,
            top: AppSpacing.xs,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.72),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationSummaryCard extends StatelessWidget {
  const LocationSummaryCard({
    super.key,
    required this.location,
    this.onAdjust,
    this.onRetry,
  });

  final ProblemLocation location;
  final VoidCallback? onAdjust;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: location.hasLowAccuracy ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(AppIcons.location, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.address, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(location.coordinates, style: AppTypography.caption),
                    Text(
                      'GPS accuracy: ±${location.accuracy.toStringAsFixed(0)} m',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (location.hasLowAccuracy) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Your location accuracy is low. Try again or adjust the pin.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onAdjust != null || onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                if (onAdjust != null)
                  TextButton.icon(
                    onPressed: onAdjust,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Adjust pin'),
                  ),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Try GPS again'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DevelopmentMapCard extends StatelessWidget {
  const DevelopmentMapCard({
    super.key,
    required this.location,
    this.onTap,
    this.height = 210,
  });

  final ProblemLocation location;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DevelopmentMap(
        location: location,
        onChanged: onTap != null ? (_) => onTap!() : null,
        isEditable: false,
        aspectRatio: 1.7,
      ),
    );
  }
}
