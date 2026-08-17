import 'package:flutter/material.dart';

import '../bootstrap_copy.dart';

class SmartNagpurBrand extends StatelessWidget {
  const SmartNagpurBrand({
    super.key,
    this.compact = false,
    this.light = false,
    this.showTagline = true,
  });

  final bool compact;
  final bool light;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = light ? Colors.white : theme.colorScheme.onSurface;
    final muted = light
        ? Colors.white.withValues(alpha: .78)
        : theme.colorScheme.onSurfaceVariant;
    final markSize = compact ? 48.0 : 72.0;

    return Semantics(
      label: '${BootstrapCopy.appName}, ${BootstrapCopy.cityServices}',
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: markSize,
            height: markSize,
            decoration: BoxDecoration(
              color: light
                  ? Colors.white.withValues(alpha: .15)
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(compact ? 15 : 23),
              border: light
                  ? Border.all(color: Colors.white.withValues(alpha: .3))
                  : null,
            ),
            child: Icon(
              Icons.location_city_rounded,
              size: compact ? 27 : 39,
              color: light ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BootstrapCopy.appName,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style:
                      (compact
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                ),
                Text(
                  BootstrapCopy.appNameMarathi,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2,
                  ),
                ),
                if (showTagline && !compact) ...[
                  const SizedBox(height: 5),
                  Text(
                    BootstrapCopy.cityServices,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
