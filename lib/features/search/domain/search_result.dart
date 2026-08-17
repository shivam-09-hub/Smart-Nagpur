import '../../../domain/domain.dart';

enum SearchResultType { service, news, announcement, faq }

extension SearchResultTypeLabel on SearchResultType {
  String get label => switch (this) {
    SearchResultType.service => 'Services',
    SearchResultType.news => 'News',
    SearchResultType.announcement => 'Announcements',
    SearchResultType.faq => 'FAQs',
  };
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.keywords,
    this.body,
    this.service,
    this.newsItem,
  });

  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final List<String> keywords;
  final String? body;
  final ServiceDefinition? service;
  final NewsItem? newsItem;

  String get searchableText =>
      [title, subtitle, ...keywords].join(' ').toLowerCase();
}
