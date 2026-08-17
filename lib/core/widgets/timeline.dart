import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppTimelineItem {
  const AppTimelineItem({
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isCurrent;
}

class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.items,
    this.accentColor = AppColors.primary,
  });

  final List<AppTimelineItem> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          _TimelineRow(
            item: items[index],
            accentColor: accentColor,
            isLast: index == items.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.accentColor,
    required this.isLast,
  });

  final AppTimelineItem item;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final active = item.isCompleted || item.isCurrent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: item.isCompleted
                        ? accentColor
                        : item.isCurrent
                        ? AppColors.surface
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? accentColor : AppColors.border,
                      width: item.isCurrent ? 4 : 2,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: item.isCompleted
                          ? accentColor.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.title.copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(item.subtitle!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
