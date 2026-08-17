import 'package:flutter/material.dart';

import '../../../core/widgets/core_widgets.dart';
import '../../../data/demo/demo_data.dart';
import '../../../domain/domain.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({this.services, this.onServiceSelected, super.key});

  static const routeName = '/services';

  final List<ServiceDefinition>? services;
  final ValueChanged<ServiceDefinition>? onServiceSelected;

  void _openService(BuildContext context, ServiceDefinition service) {
    if (onServiceSelected case final callback?) {
      callback(service);
      return;
    }
    Navigator.of(
      context,
    ).pushNamed('/services/${service.type.slug}', arguments: service);
  }

  @override
  Widget build(BuildContext context) {
    final visibleServices = services ?? DemoData.services;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            tooltip: 'Search Smart Nagpur',
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columnCount = width >= 940 ? 3 : (width >= 620 ? 2 : 1);
            final horizontalPadding = width >= 720 ? 28.0 : 20.0;
            return CustomScrollView(
              key: const PageStorageKey('services-scroll'),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How can we help you?',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose a civic service',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed('/search', arguments: 'services'),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search_rounded),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Search services and civic help',
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    32,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, _) {
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 118,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final service = visibleServices[index];
                          return _ServiceGridCard(
                            service: service,
                            onTap: () => _openService(context, service),
                          );
                        }, childCount: visibleServices.length),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  const _ServiceGridCard({required this.service, required this.onTap});

  final ServiceDefinition service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ServiceCard(service: service, onTap: onTap);
  }
}
