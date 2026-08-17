import 'package:flutter/material.dart';

import '../../../core/theme/service_theme.dart';
import '../../../domain/domain.dart';

IconData _iconForAction(ServiceAction action) {
  switch (action.kind) {
    case ServiceActionKind.information:
      return Icons.info_outline_rounded;
    case ServiceActionKind.vendorRegistration:
      return Icons.person_add_alt_1_rounded;
    case ServiceActionKind.vendorPermission:
      return Icons.post_add_rounded;
    case ServiceActionKind.vendorZones:
      return Icons.map_outlined;
    case ServiceActionKind.vendorTracking:
      return Icons.track_changes_rounded;
    case ServiceActionKind.vendorRenewal:
      return Icons.autorenew_rounded;
    case ServiceActionKind.vendorDocuments:
      return Icons.folder_copy_outlined;
    case ServiceActionKind.report:
      break;
  }

  final title = action.title.toLowerCase();
  if (title.contains('pothole')) return Icons.trip_origin_rounded;
  if (title.contains('water') || title.contains('flood')) {
    return Icons.water_drop_outlined;
  }
  if (title.contains('leak') || title.contains('pipeline')) {
    return Icons.plumbing_rounded;
  }
  if (title.contains('garbage') || title.contains('collection')) {
    return Icons.delete_outline_rounded;
  }
  if (title.contains('dumping') || title.contains('hazard')) {
    return Icons.warning_amber_rounded;
  }
  if (title.contains('road') || title.contains('footpath')) {
    return Icons.add_road_rounded;
  }
  if (title.contains('animal') || title.contains('rescue')) {
    return Icons.pets_outlined;
  }
  if (title.contains('drain')) return Icons.flood_outlined;
  if (title.contains('light')) return Icons.lightbulb_outline_rounded;
  if (title.contains('wire')) return Icons.cable_rounded;
  if (title.contains('pole')) return Icons.vertical_align_center_rounded;
  if (title.contains('park') || title.contains('playground')) {
    return Icons.park_outlined;
  }
  if (title.contains('toilet')) return Icons.wc_rounded;
  if (title.contains('encroachment') || title.contains('obstruction')) {
    return Icons.block_rounded;
  }
  if (title.contains('construction') || title.contains('excavation')) {
    return Icons.construction_rounded;
  }
  return Icons.assignment_outlined;
}

/// One visual template used by every civic service. The supplied definition
/// controls identity and actions while the page hierarchy stays consistent.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({required this.service, super.key});

  final ServiceDefinition service;

  Future<void> _openAction(BuildContext context, ServiceAction action) async {
    if (action.safetyMessage != null) {
      final continueReporting = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: service.type.color),
          title: const Text('Stay safe'),
          content: Text(
            action.safetyMessage ??
                'Keep a safe distance and do not touch damaged equipment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue safely'),
            ),
          ],
        ),
      );
      if (continueReporting != true || !context.mounted) return;
    }

    switch (action.kind) {
      case ServiceActionKind.report:
        Navigator.of(context).pushNamed(
          '/complaints/create',
          arguments: <String, Object?>{
            'serviceType': service.type,
            'serviceSlug': service.type.slug,
            'serviceTitle': service.title,
            'issue': action.title,
          },
        );
        return;
      case ServiceActionKind.information:
        _showInformation(context, action);
        return;
      case ServiceActionKind.vendorRegistration:
      case ServiceActionKind.vendorPermission:
        Navigator.of(
          context,
        ).pushNamed('/vendor/apply', arguments: {'sourceAction': action.id});
        return;
      case ServiceActionKind.vendorZones:
        Navigator.of(context).pushNamed('/vendor/zones');
        return;
      case ServiceActionKind.vendorTracking:
        Navigator.of(context).pushNamed('/vendor/application');
        return;
      case ServiceActionKind.vendorRenewal:
        Navigator.of(context).pushNamed('/vendor/renew');
        return;
      case ServiceActionKind.vendorDocuments:
        Navigator.of(context).pushNamed('/vendor/documents');
        return;
    }
  }

  void _showInformation(BuildContext context, ServiceAction action) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: service.type.softColor,
                foregroundColor: service.type.color,
                child: Icon(_iconForAction(action)),
              ),
              const SizedBox(height: 18),
              Text(
                action.title,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                action.description ??
                    'This is demo guidance. Live municipal information will be available when the city service is connected.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo information — verify details with the appropriate civic authority before relying on them.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: service.type.color,
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.shortTitle),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ServiceHero(service: service)),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.type == ServiceType.vendor
                              ? 'What would you like to do?'
                              : 'How can we help?',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service.type == ServiceType.vendor
                              ? 'Choose an option to continue.'
                              : 'Choose an issue to start a guided report.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverList.separated(
                itemCount: service.actions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final action = service.actions[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _ServiceActionTile(
                        action: action,
                        color: service.type.color,
                        softColor: service.type.softColor,
                        onTap: () => _openAction(context, action),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicePage extends ServiceDetailScreen {
  const ServicePage({required super.service, super.key});
}

class _ServiceHero extends StatelessWidget {
  const _ServiceHero({required this.service});

  final ServiceDefinition service;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                service.type.softColor,
                service.type.softColor.withAlpha(110),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(190),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'SMART NAGPUR SERVICE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: service.type.color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    service.heroTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
              );
              final illustration = Container(
                width: wide ? 128 : 82,
                height: wide ? 128 : 82,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(205),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.type.icon,
                  size: wide ? 62 : 42,
                  color: service.type.color,
                ),
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 24),
                    illustration,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [illustration, const SizedBox(height: 20), copy],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ServiceActionTile extends StatelessWidget {
  const _ServiceActionTile({
    required this.action,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  final ServiceAction action;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.title,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: action.safetyMessage != null
                ? color.withAlpha(120)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_iconForAction(action), color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (action.description case final description?) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
