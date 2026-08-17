import 'package:flutter/material.dart';

import '../../../core/theme/service_theme.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../data/demo/demo_data.dart';
import '../../../domain/domain.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({
    this.items,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  static const routeName = '/news';

  final List<NewsItem>? items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  NewsCategory? _selectedCategory;

  List<NewsItem> get _filteredItems {
    final source = widget.items ?? DemoData.news;
    if (_selectedCategory case final category?) {
      return source.where((item) => item.category == category).toList();
    }
    return source;
  }

  void _openNews(NewsItem item) {
    Navigator.of(context).pushNamed('/news/${item.id}', arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & updates'),
        actions: [
          IconButton(
            tooltip: 'Search news',
            onPressed: () =>
                Navigator.of(context).pushNamed('/search', arguments: 'news'),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const _NewsLoadingState();
    }
    if (widget.errorMessage case final message?) {
      return _NewsMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load city updates',
        message: message,
        actionLabel: 'Try again',
        onAction: widget.onRetry,
      );
    }

    final items = _filteredItems;
    return CustomScrollView(
      key: const PageStorageKey('news-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest from Nagpur',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Demo city stories, civic announcements and important alerts.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ImportantUpdatesBanner(
                      count: (widget.items ?? DemoData.news)
                          .where((item) => item.isImportant)
                          .length,
                      onTap: () {
                        final important = (widget.items ?? DemoData.news)
                            .where((item) => item.isImportant)
                            .toList();
                        if (important.isNotEmpty) {
                          _openNews(important.first);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No important updates right now.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...NewsCategory.values.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        category.icon,
                        size: 17,
                        color: _selectedCategory == category
                            ? category.color
                            : null,
                      ),
                      label: Text(category.label),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NewsMessageState(
              icon: Icons.article_outlined,
              title: 'No updates in this category',
              message: 'Choose another category to see demo city updates.',
              actionLabel: 'Show all',
              onAction: () => setState(() => _selectedCategory = null),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: NewsCard(
                    item: items[index],
                    onTap: () => _openNews(items[index]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NewsListScreen extends NewsScreen {
  const NewsListScreen({
    super.items,
    super.isLoading,
    super.errorMessage,
    super.onRetry,
    super.key,
  });
}

class _ImportantUpdatesBanner extends StatelessWidget {
  const _ImportantUpdatesBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important updates',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      count == 0
                          ? 'No important demo alerts right now'
                          : '$count demo alert${count == 1 ? '' : 's'} available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsMessageState extends StatelessWidget {
  const _NewsMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsLoadingState extends StatelessWidget {
  const _NewsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading news and updates',
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
