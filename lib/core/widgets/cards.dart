import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/domain.dart';
import '../theme/theme.dart';
import 'status_badge.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final ServiceDefinition service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = service.type.color;
    return Semantics(
      button: true,
      label: service.title,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: service.type.softColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(service.type.icon, color: accent, size: 27),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: AppTypography.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        service.description,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(item.publishedAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: item.category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.category.icon,
                          size: 14,
                          color: item.category.color,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          item.category.label,
                          style: AppTypography.caption.copyWith(
                            color: item.category.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(date, style: AppTypography.caption),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(item.title, style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.summary,
                style: AppTypography.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.isDemo) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'DEMO CONTENT',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onTap});

  final ComplaintRecord request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(request.createdAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                      color: request.serviceType.softColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      request.serviceType.icon,
                      color: request.serviceType.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.issue, style: AppTypography.title),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${request.serviceType.shortTitle} · $date',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusBadge.complaint(request.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      request.location.address,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
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

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onTap,
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningSoft,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(message, style: AppTypography.bodySmall),
                    if (actionLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        actionLabel!,
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTypography.label),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmationCard extends StatelessWidget {
  const ConfirmationCard({
    super.key,
    required this.title,
    required this.message,
    this.referenceLabel,
    this.referenceValue,
  });

  final String title;
  final String message;
  final String? referenceLabel;
  final String? referenceValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: AppColors.success,
            size: 52,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (referenceValue != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              referenceLabel ?? 'Reference ID',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.xxs),
            SelectableText(
              referenceValue!,
              style: AppTypography.title.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
