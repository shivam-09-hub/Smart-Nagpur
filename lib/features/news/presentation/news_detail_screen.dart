import 'package:flutter/material.dart';

import '../../../core/theme/service_theme.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../data/demo/demo_data.dart';
import '../../../domain/domain.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({required this.item, this.allItems, super.key});

  final NewsItem item;
  final List<NewsItem>? allItems;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(item.publishedAt);
    final related = (allItems ?? DemoData.news)
        .where((candidate) => candidate.id != item.id)
        .take(2)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('City update'),
        actions: [
          IconButton(
            tooltip: 'Share update',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sharing is available in the connected release.'),
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: item.category.color.withValues(alpha: .1),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CategoryBadge(item: item),
                              if (item.isDemo) const _DemoBadge(),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -.6,
                                ),
                          ),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 18),
                              const SizedBox(width: 7),
                              Text(
                                date,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.summary,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          item.content,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.7),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Development preview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'This is clearly labelled demo content. Live updates will require a verified municipal data connection.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (related.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'More city updates',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/news'),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: related.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: NewsCard(
                        item: related[index],
                        onTap: () => Navigator.of(context).pushReplacementNamed(
                          '/news/${related[index].id}',
                          arguments: related[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: item.category.color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.category.icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            item.category.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        'DEMO UPDATE',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
