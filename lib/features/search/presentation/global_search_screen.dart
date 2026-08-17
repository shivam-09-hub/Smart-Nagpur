import 'package:flutter/material.dart';

import '../../../core/theme/service_theme.dart';
import '../../../data/demo/demo_data.dart';
import '../../../domain/domain.dart';
import '../data/search_index.dart';
import '../domain/search_result.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    this.initialQuery,
    this.services,
    this.news,
    super.key,
  });

  static const routeName = '/search';

  final String? initialQuery;
  final List<ServiceDefinition>? services;
  final List<NewsItem>? news;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  SearchResultType? _selectedType;

  static const _suggestions = <String>[
    'garbage',
    'water leakage',
    'vendor registration',
    'road complaint',
  ];

  @override
  void initState() {
    super.initState();
    final requested = widget.initialQuery?.trim();
    _controller = TextEditingController(
      text: requested == null || requested == 'services' || requested == 'news'
          ? ''
          : requested,
    )..addListener(_onQueryChanged);
    if (requested == 'services') _selectedType = SearchResultType.service;
    if (requested == 'news') _selectedType = SearchResultType.news;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() => setState(() {});

  List<GlobalSearchResult> get _results {
    final query = _controller.text.trim().toLowerCase();
    final index = SearchIndex.build(
      services: widget.services ?? DemoData.services,
      news: widget.news ?? DemoData.news,
    );
    if (query.isEmpty) return const [];
    final tokens = query
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    final scored = <(GlobalSearchResult, int)>[];
    for (final result in index) {
      if (_selectedType != null && result.type != _selectedType) continue;
      final text = result.searchableText;
      if (!tokens.every(text.contains)) continue;
      var score = 0;
      if (result.title.toLowerCase().startsWith(query)) score += 6;
      if (result.title.toLowerCase().contains(query)) score += 3;
      if (result.subtitle.toLowerCase().contains(query)) score += 1;
      scored.add((result, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((entry) => entry.$1).toList();
  }

  void _selectSuggestion(String query) {
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _focusNode.unfocus();
  }

  void _openResult(GlobalSearchResult result) {
    switch (result.type) {
      case SearchResultType.service:
        final service = result.service!;
        Navigator.of(
          context,
        ).pushNamed('/services/${service.type.slug}', arguments: service);
        return;
      case SearchResultType.news:
        final item = result.newsItem!;
        Navigator.of(context).pushNamed('/news/${item.id}', arguments: item);
        return;
      case SearchResultType.announcement:
      case SearchResultType.faq:
        _showTextResult(result);
        return;
    }
  }

  void _showTextResult(GlobalSearchResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultIcon(type: result.type),
              const SizedBox(height: 18),
              Text(
                result.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                result.body ?? result.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
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
    final query = _controller.text.trim();
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Search Smart Nagpur')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: SearchBar(
                    controller: _controller,
                    focusNode: _focusNode,
                    autoFocus: true,
                    hintText: 'Search services, news, announcements, FAQs',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          onPressed: _controller.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                    onSubmitted: (_) => _focusNode.unfocus(),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 3,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedType == null,
                      onSelected: (_) => setState(() => _selectedType = null),
                    ),
                  ),
                  ...SearchResultType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type.label),
                        selected: _selectedType == type,
                        onSelected: (_) => setState(() => _selectedType = type),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? _SearchStart(
                      suggestions: _suggestions,
                      onSelected: _selectSuggestion,
                    )
                  : results.isEmpty
                  ? _NoSearchResults(query: query, onClear: _controller.clear)
                  : _SearchResults(
                      query: query,
                      results: results,
                      onTap: _openResult,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends GlobalSearchScreen {
  const SearchScreen({
    super.initialQuery,
    super.services,
    super.news,
    super.key,
  });
}

class _SearchStart extends StatelessWidget {
  const _SearchStart({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.travel_explore_rounded,
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What do you need help with?',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Search across local demo services and information.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Try searching for',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: suggestions
                      .map(
                        (suggestion) => ActionChip(
                          avatar: const Icon(
                            Icons.north_west_rounded,
                            size: 17,
                          ),
                          label: Text(suggestion),
                          onPressed: () => onSelected(suggestion),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.onTap,
  });

  final String query;
  final List<GlobalSearchResult> results;
  final ValueChanged<GlobalSearchResult> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: results.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Text(
                '${results.length} result${results.length == 1 ? '' : 's'} for “$query”',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        final result = results[index - 1];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: _SearchResultTile(
              result: result,
              onTap: () => onTap(result),
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final GlobalSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${result.type.label}: ${result.title}',
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _ResultIcon(type: result.type, service: result.service),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.type.label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        result.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        result.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultIcon extends StatelessWidget {
  const _ResultIcon({required this.type, this.service});

  final SearchResultType type;
  final ServiceDefinition? service;

  @override
  Widget build(BuildContext context) {
    final color =
        service?.type.color ??
        switch (type) {
          SearchResultType.service => Theme.of(context).colorScheme.primary,
          SearchResultType.news => const Color(0xFF2867D6),
          SearchResultType.announcement => const Color(0xFFE07A16),
          SearchResultType.faq => const Color(0xFF7C4BB2),
        };
    final icon =
        service?.type.icon ??
        switch (type) {
          SearchResultType.service => Icons.grid_view_rounded,
          SearchResultType.news => Icons.article_outlined,
          SearchResultType.announcement => Icons.campaign_outlined,
          SearchResultType.faq => Icons.help_outline_rounded,
        };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for “$query”',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a shorter phrase or search all categories.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}
