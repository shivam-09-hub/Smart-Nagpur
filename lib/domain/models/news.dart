enum NewsCategory {
  cityUpdates,
  roadWork,
  water,
  waste,
  publicNotices,
  events,
  emergencyAlerts,
}

extension NewsCategoryDetails on NewsCategory {
  String get label => switch (this) {
    NewsCategory.cityUpdates => 'City updates',
    NewsCategory.roadWork => 'Road work',
    NewsCategory.water => 'Water',
    NewsCategory.waste => 'Waste',
    NewsCategory.publicNotices => 'Public notices',
    NewsCategory.events => 'Events',
    NewsCategory.emergencyAlerts => 'Emergency alerts',
  };
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
    this.isImportant = false,
    this.isDemo = true,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final NewsCategory category;
  final DateTime publishedAt;
  final String? imageUrl;
  final bool isImportant;
  final bool isDemo;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'content': content,
    'category': category.name,
    'publishedAt': publishedAt.toIso8601String(),
    'imageUrl': imageUrl,
    'isImportant': isImportant,
    'isDemo': isDemo,
  };

  factory NewsItem.fromJson(Map<String, Object?> json) {
    return NewsItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: NewsCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => NewsCategory.cityUpdates,
      ),
      publishedAt:
          (DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.now()).toLocal(),
      imageUrl: json['imageUrl'] as String?,
      isImportant: json['isImportant'] as bool? ?? false,
      isDemo: json['isDemo'] as bool? ?? true,
    );
  }
}
