import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
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
    return Semantics(
      button: onTap != null,
      label: 'Development map placeholder at ${location.coordinates}',
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MapGridPainter()),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_pin,
                        size: 48,
                        color: AppColors.error,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: AppShadows.card,
                        ),
                        child: Text(
                          location.coordinates,
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        'DEVELOPMENT MAP',
                        style: AppTypography.caption,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.86)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final minorPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 54) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x + size.height, size.height),
        minorPaint,
      );
    }
    for (var y = 28.0; y < size.height; y += 62) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), roadPaint);
    }
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.72, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}
